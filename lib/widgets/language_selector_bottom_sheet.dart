import 'package:flutter/material.dart';
import '../core/extensions/context_extensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';

class LanguageSelectorBottomSheet extends StatelessWidget {
  const LanguageSelectorBottomSheet({super.key});

  static void show(BuildContext context) {
    final isHC = context.isHighContrast;

    showModalBottomSheet(
      context: context,
      backgroundColor: isHC ? Colors.white : context.cardColor,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isHC ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
      ),
      builder: (_) => const LanguageSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = localeProvider.locale.languageCode;
    final isHC = context.isHighContrast;
    final hasLargeTargets = context.hasLargeTargets;

    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'name': 'Sinhala', 'nativeName': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்', 'flag': '🇱🇰'},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isHC ? Colors.black : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header title
            Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  size: 24,
                  color: isHC ? Colors.black : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  context.loc.selectLanguageTitle,
                  style: TextStyle(
                    fontSize: hasLargeTargets ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: isHC ? Colors.black : context.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language cards
            ...languages.map((lang) {
              final isSelected = currentLocale == lang['code'];
              final activeColor = isHC ? const Color(0xFF001F3F) : AppColors.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      localeProvider.setLocale(Locale(lang['code']!));
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: hasLargeTargets ? 18 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isHC ? const Color(0xFFE5E5E5) : AppColors.primaryContainer.withValues(alpha: 0.12))
                            : (isHC ? Colors.white : AppColors.surfaceContainerLowest),
                        borderRadius: BorderRadius.circular(16),
                        border: isHC
                            ? Border.all(
                                color: Colors.black,
                                width: isSelected ? 2.5 : 1.5,
                              )
                            : Border.all(
                                color: isSelected ? activeColor : AppColors.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: TextStyle(fontSize: hasLargeTargets ? 28 : 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['nativeName']!,
                                  style: TextStyle(
                                    fontSize: hasLargeTargets ? 17 : 16,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? activeColor : context.textColor,
                                  ),
                                ),
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    fontSize: hasLargeTargets ? 13 : 12,
                                    color: isHC ? Colors.black87 : context.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
