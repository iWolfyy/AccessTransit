import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Displays a confirmation dialog asking the user to confirm signing out.
///
/// Returns `true` if the user confirms, or `false`/`null` if cancelled.
Future<bool?> showLogoutConfirmationDialog(BuildContext context) {
  final isHighContrast = context.isHighContrast;
  final hasLargeTargets = context.hasLargeTargets;
  final dangerColor = isHighContrast ? const Color(0xFF8B0000) : AppColors.error;

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: isHighContrast ? Colors.white : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isHighContrast
              ? const BorderSide(color: Colors.black, width: 2.0)
              : BorderSide.none,
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? const Color(0xFFFFEBEE)
                    : dangerColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: dangerColor,
                size: hasLargeTargets ? 26 : 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: hasLargeTargets ? 21 : 19,
                  fontWeight: FontWeight.w700,
                  color: isHighContrast ? Colors.black : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? You will need to sign back in to access your saved journeys, active passes, and community reports.',
          style: TextStyle(
            fontSize: hasLargeTargets ? 16 : 14,
            height: 1.45,
            color: isHighContrast ? const Color(0xFF1E1E1E) : AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isHighContrast ? Colors.black : AppColors.onSurface,
                    side: BorderSide(
                      color: isHighContrast ? Colors.black : AppColors.outlineVariant,
                      width: isHighContrast ? 2.0 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(0, context.minTapHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 16 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: isHighContrast
                        ? const BorderSide(color: Colors.black, width: 2.0)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(0, context.minTapHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: hasLargeTargets ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Helper to show a post-logout confirmation message (SnackBar).
void showLogoutSuccessSnackBar({
  BuildContext? context,
  ScaffoldMessengerState? messenger,
  bool isHighContrast = false,
}) {
  final targetMessenger =
      messenger ?? (context != null ? ScaffoldMessenger.of(context) : null);
  if (targetMessenger == null) return;

  final hc = isHighContrast || (context != null && context.isHighContrast);

  targetMessenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You have been signed out successfully.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: hc ? Colors.black : const Color(0xFF22262E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
}
