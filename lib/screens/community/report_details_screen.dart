import 'dart:io';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
              icon: Icon(Icons.close_rounded, color: Colors.white, size: context.tapIconSize + 4),
              tooltip: 'Close',
              constraints: context.appBarActionConstraints,
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

    final isHC = context.isHighContrast;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor, size: context.tapIconSize),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          constraints: context.appBarActionConstraints,
        ),
        title: Text(
          'Report Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isHC ? Colors.black : AppColors.primary,
              size: context.tapIconSize,
            ),
            onPressed: () => _shareReport(report, targetTitle),
            tooltip: 'Share alert',
            constraints: context.appBarActionConstraints,
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
                      color: isHC ? Colors.white : AppColors.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isHC ? const Color(0xFF8B0000) : AppColors.error.withValues(alpha: 0.4),
                        width: isHC ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_off_rounded,
                          color: isHC ? const Color(0xFF8B0000) : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This report has been hidden due to multiple false reports from commuters.',
                            style: TextStyle(
                              color: isHC ? const Color(0xFF8B0000) : AppColors.error,
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
    final isHC = context.isHighContrast;
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String statusTitle;
    final String statusSubtitle;

    if (isResolved) {
      bgColor = isHC ? Colors.white : AppColors.success.withValues(alpha: 0.12);
      fgColor = isHC ? const Color(0xFF003833) : AppColors.success;
      icon = Icons.check_circle_rounded;
      statusTitle = 'Condition Resolved';
      statusSubtitle = 'This accessibility issue has been marked fixed.';
    } else if (confirmCount > 0 && isReportActive) {
      bgColor = isHC ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.35);
      fgColor = isHC ? const Color(0xFF001F3F) : AppColors.primary;
      icon = Icons.verified_rounded;
      statusTitle = 'Community Verified Live';
      statusSubtitle = 'Confirmed by $confirmCount fellow rider${confirmCount == 1 ? "" : "s"}.';
    } else if (isReportActive) {
      bgColor = isHC ? Colors.white : const Color(0xFFFFF3E0);
      fgColor = isHC ? const Color(0xFF8B0000) : const Color(0xFFE65100);
      icon = Icons.bolt_rounded;
      statusTitle = 'Active Transit Alert';
      statusSubtitle = 'Recently reported by a commuter. Real-time active.';
    } else {
      bgColor = isHC ? Colors.white : AppColors.surfaceContainer;
      fgColor = isHC ? Colors.black : AppColors.outline;
      icon = Icons.history_rounded;
      statusTitle = 'Past Report (Expired)';
      statusSubtitle = 'This report was active earlier and is now archived.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHC ? fgColor : fgColor.withValues(alpha: 0.3),
          width: isHC ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isHC ? Colors.white : fgColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: isHC ? Border.all(color: fgColor, width: 1.5) : null,
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
                          color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                          border: isHC ? Border.all(color: Colors.black, width: 1) : null,
                        ),
                        child: const Text(
                          'YOUR REPORT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                    color: isHC ? Colors.black : fgColor.withValues(alpha: 0.85),
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
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
        boxShadow: isHC
            ? null
            : [
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
                  color: isHC
                      ? Colors.white
                      : AppColors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Icon(
                  isBus ? Icons.directions_bus_rounded : Icons.store_mall_directory_rounded,
                  size: 24,
                  color: isHC ? Colors.black : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBus
                          ? 'Transit Vehicle • ${report?.targetId ?? widget.vehicleLabel}'
                          : 'Transit Station • ${report?.targetId ?? "Central Corridor"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHC ? Colors.white : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Text(
                  isBus ? 'BUS' : 'STATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isHC ? Colors.black : AppColors.onSurfaceVariant,
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
    final isHC = context.isHighContrast;
    final severity = report?.severity.toLowerCase() ?? 'moderate';
    final Color severityColor;
    final String severityLabel;

    switch (severity) {
      case 'major':
        severityColor = isHC ? const Color(0xFF8B0000) : AppColors.error;
        severityLabel = 'High Severity';
        break;
      case 'minor':
        severityColor = isHC ? const Color(0xFF003833) : AppColors.success;
        severityLabel = 'Minor Issue';
        break;
      case 'moderate':
      default:
        severityColor = isHC ? const Color(0xFF8B4500) : const Color(0xFFF57F17);
        severityLabel = 'Moderate';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
        boxShadow: isHC
            ? null
            : [
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
          Text(
            'Reported Condition Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: context.subtextColor,
            ),
          ),
          const SizedBox(height: 8),

          // Main Issue Name
          Text(
            displayTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: context.textColor,
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
                  color: isHC ? Colors.white : severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: severityColor,
                    width: isHC ? 2 : 1,
                  ),
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
                    color: isHC
                        ? Colors.white
                        : AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: isHC
                        ? Border.all(color: const Color(0xFF001F3F), width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 14,
                        color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCategoryName(report.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isHC ? const Color(0xFF001F3F) : AppColors.primary,
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
                color: isHC ? Colors.white : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHC
                      ? Colors.black
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: isHC ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: isHC ? Colors.black : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rider Note:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isHC ? Colors.black : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '“${report.description.trim()}”',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPhotoEvidenceCard(photoUrl!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImageWidget(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImageFallback(),
      );
    }

    try {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageFallback(),
        );
      }
    } catch (_) {}

    return Image.network(
      pathOrUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImageFallback(),
    );
  }

  Widget _buildPhotoEvidenceCard(String photoPath) {
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showFullPhotoDialog(photoPath),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: photoPath.startsWith('http')
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
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    final isHC = context.isHighContrast;
    return Container(
      height: 220,
      width: double.infinity,
      color: isHC ? Colors.white : AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: isHC ? Colors.black : AppColors.outline),
          const SizedBox(height: 8),
          Text(
            'Image preview unavailable',
            style: TextStyle(color: isHC ? Colors.black : AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    final isHC = context.isHighContrast;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isHC ? Colors.white : AppColors.surfaceContainer,
        border: isHC ? Border.all(color: Colors.black, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: isHC ? Colors.black : AppColors.outline,
          ),
          const SizedBox(width: 8),
          Text(
            'Photo unavailable',
            style: TextStyle(
              color: isHC ? Colors.black : AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Trust & verification timeline card
  Widget _buildTrustTimelineCard(Report report) {
    final isHC = context.isHighContrast;
    final reportedAgo = TimeUtils.formatRelativeTime(report.createdAt);
    final confirmedAgo = report.lastConfirmedAt != null
        ? TimeUtils.formatRelativeTime(report.lastConfirmedAt!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Trust & Verification Metrics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.subtextColor,
            ),
          ),
          const SizedBox(height: 12),
          // True Count Row
          Row(
            children: [
              Icon(
                Icons.thumb_up_alt_rounded,
                size: 16,
                color: isHC ? const Color(0xFF003833) : AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'True Flags (Confirmed): ${report.confirmCount} rider${report.confirmCount == 1 ? "" : "s"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isHC ? const Color(0xFF003833) : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // False Count Row
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                size: 16,
                color: isHC ? const Color(0xFF8B0000) : (report.falseCount > 0 ? AppColors.error : AppColors.outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'False Flags: ${report.falseCount} / 3 (Report deletes/hides at 3 false flags)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isHC ? const Color(0xFF8B0000) : (report.falseCount > 0 ? AppColors.error : context.textColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isHC ? Colors.black : AppColors.outlineVariant, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: isHC ? Colors.black : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Originally reported: $reportedAgo',
                  style: TextStyle(fontSize: 12, color: context.subtextColor),
                ),
              ),
            ],
          ),
          if (confirmedAgo != null && report.confirmCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: isHC ? const Color(0xFF003833) : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last confirmed: $confirmedAgo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHC ? const Color(0xFF003833) : AppColors.success,
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

  /// Action buttons: Confirm condition (True Flag), Report as False (False Flag), Mark Resolved
  Widget _buildActionPanel({
    required Report report,
    required bool isReportActive,
    required bool isResolved,
    required bool hasConfirmed,
    required bool hasFlagged,
    required bool isAuthor,
  }) {
    final isHC = context.isHighContrast;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHC
            ? Border.all(color: Colors.black, width: 2)
            : Border.all(color: AppColors.outlineVariant),
        boxShadow: isHC
            ? null
            : [
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
          Text(
            'Vote Report Accuracy',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Click True if the issue exists, or False flag if it is inaccurate. 3 False flags will delete the report.',
            style: TextStyle(
              fontSize: 13,
              color: context.subtextColor,
            ),
          ),
          const SizedBox(height: 16),

          // Primary Flag Buttons Row: True Flag vs False Flag
          Row(
            children: [
              // 1. True Flag Button
              Expanded(
                child: SizedBox(
                  height: context.buttonHeight,
                  child: FilledButton.icon(
                    onPressed: (hasConfirmed || _isLoadingAction)
                        ? null
                        : () => _handleConfirm(report),
                    style: FilledButton.styleFrom(
                      backgroundColor: isHC ? const Color(0xFF001F3F) : AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isHC ? Colors.white : AppColors.surfaceContainer,
                      disabledForegroundColor: isHC ? Colors.grey : AppColors.outline,
                      side: isHC
                          ? BorderSide(
                              color: (hasConfirmed || isResolved) ? Colors.grey : Colors.black,
                              width: 2,
                            )
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      hasConfirmed ? Icons.check_rounded : Icons.thumb_up_rounded,
                      size: 18,
                    ),
                    label: Text(
                      hasConfirmed ? 'True (${report.confirmCount})' : 'True Flag (${report.confirmCount})',
                      style: TextStyle(
                        fontSize: context.hasLargeTargets ? 14 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. False Flag Button
              Expanded(
                child: SizedBox(
                  height: context.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: (hasFlagged || _isLoadingAction || isResolved)
                        ? null
                        : () => _handleFlag(report),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isHC ? Colors.white : null,
                      foregroundColor: isHC ? const Color(0xFF8B0000) : AppColors.error,
                      side: BorderSide(
                        color: hasFlagged
                            ? (isHC ? Colors.grey : AppColors.outlineVariant)
                            : (isHC ? const Color(0xFF8B0000) : AppColors.error),
                        width: isHC ? 2 : 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(hasFlagged ? Icons.flag_rounded : Icons.flag_outlined, size: 18),
                    label: Text(
                      hasFlagged ? 'False (${report.falseCount}/3)' : 'False Flag (${report.falseCount}/3)',
                      style: TextStyle(
                        fontSize: context.hasLargeTargets ? 14 : 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mark Resolved Button
          SizedBox(
            height: context.buttonHeight - 4,
            child: OutlinedButton.icon(
              onPressed: (isResolved || _isLoadingAction)
                  ? null
                  : () => _handleResolve(report),
              style: OutlinedButton.styleFrom(
                backgroundColor: isHC ? Colors.white : null,
                foregroundColor: isHC ? const Color(0xFF003833) : AppColors.success,
                side: BorderSide(
                  color: isResolved
                      ? (isHC ? Colors.grey : AppColors.outlineVariant)
                      : (isHC ? const Color(0xFF003833) : AppColors.success),
                  width: isHC ? 2 : 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(
                isResolved ? 'Condition Marked Fixed' : 'Mark Condition as Fixed / Resolved',
                style: TextStyle(
                  fontSize: context.hasLargeTargets ? 14 : 13,
                  fontWeight: FontWeight.w700,
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
