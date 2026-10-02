import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_utils.dart';
import '../../logic/status_logic.dart';
import '../../models/report.dart';
import '../../services/firestore_service.dart';

/// Modern Accessible Report Details Screen matching the LMT Go design language.
class ReportDetailsScreen extends StatefulWidget {
  const ReportDetailsScreen({
    super.key,
    this.report,
    this.reportId,
    this.targetTitle = 'Central Station',
    this.title = 'Condition Report',
    this.reportedAgo = 'Recently reported',
    this.vehicleLabel = 'Transit Vehicle',
    this.routeLabel = 'Route Details',
    this.crowdLevel = 'Moderate',
    this.accessibilityLabel = 'Limited',
    this.quote = '',
    this.mapLocationLabel = '',
    this.communityVerified = false,
    this.mapImageUrl = '',
  });

  final Report? report;
  final String? reportId;
  final String targetTitle;
  final String title;
  final String reportedAgo;
  final String vehicleLabel;
  final String routeLabel;
  final String crowdLevel;
  final String accessibilityLabel;
  final String quote;
  final String mapLocationLabel;
  final bool communityVerified;
  final String mapImageUrl;

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  static const double _desktopBreakpoint = 768;
  bool _isLoadingAction = false;
  static String? _cachedGuestUserId;

  String _getOrCreateUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    _cachedGuestUserId ??=
        'guest_user_${DateTime.now().millisecondsSinceEpoch}';
    return _cachedGuestUserId!;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  Future<void> _handleConfirm(Report report) async {
    final userId = _getOrCreateUserId();
    if (report.confirmedBy.contains(userId)) {
      _showSnack('You already confirmed this condition report.');
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().confirmReport(report.id, userId);
      _showSnack('Condition confirmed! Expiry timer refreshed.');
    } catch (e) {
      _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleResolve(Report report) async {
    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().resolveReport(report.id);
      _showSnack('Thank you! Report marked as resolved.');
    } catch (e) {
      _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _handleFlag(Report report) async {
    final userId = _getOrCreateUserId();
    if (report.flaggedBy.contains(userId)) {
      _showSnack('You already flagged this report.');
      return;
    }

    setState(() => _isLoadingAction = true);
    try {
      await FirestoreService().flagReport(report.id, userId);
      _showSnack('Report flagged as false.');
    } catch (e) {
      _showSnack('Action failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _shareReport(Report? report, String targetTitle) {
    final title = report?.problemType ?? widget.title;
    final text = 'AccessTransit Alert: $title at $targetTitle. Check live status in AccessTransit.';
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Alert link & text copied to clipboard!');
  }

  void _showFullPhotoDialog(String photoPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.5,
              child: photoPath.startsWith('http')
                  ? Image.network(
                      photoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text(
                          'Image preview unavailable',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  : Image.file(
                      File(photoPath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text(
                          'Image preview unavailable',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
            ),
            IconButton(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              tooltip: 'Close',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final targetReportId = widget.report?.id ?? widget.reportId ?? '';

    if (targetReportId.isNotEmpty) {
      return StreamBuilder<Report?>(
        stream: FirestoreService().streamReportById(targetReportId),
        builder: (context, snapshot) {
          final currentReport = snapshot.data ??
              widget.report ??
              Report(
                id: targetReportId,
                targetType: 'station',
                targetId: '',
                targetName: widget.targetTitle,
                problemType: widget.title,
                status: 'active',
                createdAt: DateTime.now(),
                userId: '',
              );

          return _buildScaffold(context, isDesktop, currentReport);
        },
      );
    }

    return _buildScaffold(context, isDesktop, widget.report);
  }

  Widget _buildScaffold(BuildContext context, bool isDesktop, Report? report) {
    final userId = _getOrCreateUserId();
    final isReportActive = report != null ? StatusLogic.isReportActive(report) : true;
    final isResolved = report?.status.toLowerCase() == 'resolved';
    final isHidden = report?.status.toLowerCase() == 'hidden';
    final hasConfirmed = report?.confirmedBy.contains(userId) ?? false;
    final hasFlagged = report?.flaggedBy.contains(userId) ?? false;
    final isAuthor = report != null && report.userId.isNotEmpty && report.userId == userId;

    final displayTitle = report?.problemType ?? widget.title;
    final targetTitle = (report?.targetName.trim().isNotEmpty == true)
        ? report!.targetName
        : widget.targetTitle;
    final isBus = report?.targetType.toLowerCase() == 'bus';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () => _shareReport(report, targetTitle),
            tooltip: 'Share alert',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, isDesktop ? 24 : 12, 16, 40),
              children: [
                // 1. Status Banner Header
                _buildStatusBanner(
                  isResolved: isResolved,
                  isReportActive: isReportActive,
                  confirmCount: report?.confirmCount ?? 0,
                  isAuthor: isAuthor,
                ),
                const SizedBox(height: 16),

                // 2. Target Location & Identity Card
                _buildTargetCard(
                  report: report,
                  targetTitle: targetTitle,
                  isBus: isBus,
                  isAuthor: isAuthor,
                ),
                const SizedBox(height: 16),

                // 3. Condition Details Card (Crowding + Accessibility breakdown)
                _buildConditionBreakdownCard(
                  report: report,
                  displayTitle: displayTitle,
                  isBus: isBus,
                ),
                const SizedBox(height: 16),

                // 4. Photo Evidence Card (if attached)
                if (report != null && report.photoUrl.isNotEmpty) ...[
                  _buildPhotoEvidenceCard(report.photoUrl),
                  const SizedBox(height: 16),
                ],

                // 5. Verification Timeline & Trust Meter
                if (report != null) ...[
                  _buildTrustTimelineCard(report),
                  const SizedBox(height: 20),
                ],

                // 6. Action Panel (Confirm, Resolve, Flag)
                if (report != null && !isHidden) ...[
                  _buildActionPanel(
                    report: report,
                    isReportActive: isReportActive,
                    isResolved: isResolved,
                    hasConfirmed: hasConfirmed,
                    hasFlagged: hasFlagged,
                    isAuthor: isAuthor,
                  ),
                ] else if (isHidden) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off_rounded, color: AppColors.error),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This report has been hidden due to multiple false reports from commuters.',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner displaying the live status of the report (Resolved, Verified, Active, Past)
  Widget _buildStatusBanner({
    required bool isResolved,
    required bool isReportActive,
    required int confirmCount,
    required bool isAuthor,
  }) {
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String statusTitle;
    final String statusSubtitle;

    if (isResolved) {
      bgColor = AppColors.success.withValues(alpha: 0.12);
      fgColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      statusTitle = 'Condition Resolved';
      statusSubtitle = 'This accessibility issue has been marked fixed.';
    } else if (confirmCount > 0 && isReportActive) {
      bgColor = AppColors.primaryContainer.withValues(alpha: 0.35);
      fgColor = AppColors.primary;
      icon = Icons.verified_rounded;
      statusTitle = 'Community Verified Live';
      statusSubtitle = 'Confirmed by $confirmCount fellow rider${confirmCount == 1 ? "" : "s"}.';
    } else if (isReportActive) {
      bgColor = const Color(0xFFFFF3E0);
      fgColor = const Color(0xFFE65100);
      icon = Icons.bolt_rounded;
      statusTitle = 'Active Transit Alert';
      statusSubtitle = 'Recently reported by a commuter. Real-time active.';
    } else {
      bgColor = AppColors.surfaceContainer;
      fgColor = AppColors.outline;
      icon = Icons.history_rounded;
      statusTitle = 'Past Report (Expired)';
      statusSubtitle = 'This report was active earlier and is now archived.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fgColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: fgColor,
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOUR REPORT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: fgColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Target location card (Bus route / stop name / vehicle identifier)
  Widget _buildTargetCard({
    required Report? report,
    required String targetTitle,
    required bool isBus,
    required bool isAuthor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBus ? Icons.directions_bus_rounded : Icons.store_mall_directory_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBus
                          ? 'Transit Vehicle • ${report?.targetId ?? widget.vehicleLabel}'
                          : 'Transit Station • ${report?.targetId ?? "Central Corridor"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBus ? 'BUS' : 'STATION',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Breakdown card of Crowding and Accessibility issue details
  Widget _buildConditionBreakdownCard({
    required Report? report,
    required String displayTitle,
    required bool isBus,
  }) {
    final severity = report?.severity.toLowerCase() ?? 'moderate';
    final Color severityColor;
    final String severityLabel;

    switch (severity) {
      case 'major':
        severityColor = AppColors.error;
        severityLabel = 'High Severity';
        break;
      case 'minor':
        severityColor = AppColors.success;
        severityLabel = 'Minor Issue';
        break;
      case 'moderate':
      default:
        severityColor = const Color(0xFFF57F17);
        severityLabel = 'Moderate';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reported Condition Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Main Issue Name
          Text(
            displayTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Chips row: Severity, Category
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Severity Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: severityColor),
                    const SizedBox(width: 4),
                    Text(
                      severityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Category Chip
              if (report != null && report.category.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatCategoryName(report.category),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // User Note Quote if present
          if (report != null && report.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 16, color: AppColors.onSurfaceVariant),
                      SizedBox(width: 4),
                      Text(
                        'Rider Note:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“${report.description.trim()}”',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Photo Evidence Card supporting local files and network URLs
  Widget _buildPhotoEvidenceCard(String photoPath) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_camera_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Attached Photo Evidence',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showFullPhotoDialog(photoPath),
              child: Stack(
                children: [
                  photoPath.startsWith('http')
                      ? Image.network(
                          photoPath,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildImageFallback(),
                        )
                      : Image.file(
                          File(photoPath),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildImageFallback(),
                        ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Tap to enlarge',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 100,
      color: AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: AppColors.outline),
          SizedBox(width: 8),
          Text(
            'Photo unavailable',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Trust & verification timeline card
  Widget _buildTrustTimelineCard(Report report) {
    final reportedAgo = TimeUtils.formatRelativeTime(report.createdAt);
    final confirmedAgo = report.lastConfirmedAt != null
        ? TimeUtils.formatRelativeTime(report.lastConfirmedAt!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Trust & History',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Originally reported: $reportedAgo',
                  style: const TextStyle(fontSize: 13, color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          if (confirmedAgo != null && report.confirmCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last confirmed: $confirmedAgo (${report.confirmCount} rider${report.confirmCount == 1 ? "" : "s"})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Action buttons: Confirm condition, Mark Resolved, Report as False
  Widget _buildActionPanel({
    required Report report,
    required bool isReportActive,
    required bool isResolved,
    required bool hasConfirmed,
    required bool hasFlagged,
    required bool isAuthor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Help Fellow Commuters',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Confirm if this condition is still present or if it has been fixed.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions Row: Confirm (+1) vs Mark Resolved
          Row(
            children: [
              // 1. Confirm Condition Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: (hasConfirmed || _isLoadingAction || isResolved)
                        ? null
                        : () => _handleConfirm(report),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainer,
                      disabledForegroundColor: AppColors.outline,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      hasConfirmed ? Icons.check_rounded : Icons.thumb_up_rounded,
                      size: 18,
                    ),
                    label: Text(
                      hasConfirmed ? 'Confirmed' : 'Still Broken (+1)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Mark Resolved Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (isResolved || _isLoadingAction)
                        ? null
                        : () => _handleResolve(report),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: BorderSide(
                        color: isResolved
                            ? AppColors.outlineVariant
                            : AppColors.success,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      isResolved ? 'Resolved' : 'Mark Fixed',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Flag false button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: (hasFlagged || _isLoadingAction)
                  ? null
                  : () => _handleFlag(report),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: Text(
                hasFlagged ? 'Flagged as Inaccurate' : 'Report as Inaccurate',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'rampAccess':
        return 'Ramp & Access';
      case 'elevatorOut':
        return 'Elevator / Lift';
      case 'crowding':
        return 'Crowding';
      case 'cleanliness':
        return 'Cleanliness';
      case 'safetyHazard':
        return 'Safety Hazard';
      default:
        return category;
    }
  }
}
