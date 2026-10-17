import 'accessible_dropdown.dart';

import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';
import '../services/language_preferences_service.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key, this.service, this.settingsCard = false});

  final LanguagePreferencesService? service;
  final bool settingsCard;

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  bool _saving = false;
  int _revision = 0;

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? LanguagePreferencesService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final dropdown = DropdownButtonFormField<String>(
          key: ValueKey(
            '${service.userId}:${service.locale.languageCode}:$_revision',
          ),
          initialValue: service.locale.languageCode,
          isExpanded: true,
          isDense: false,
          selectedItemBuilder: (context) => const [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('English'),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('\u0dc3\u0dd2\u0d82\u0dc4\u0dbd'),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('\u0ba4\u0bae\u0bbf\u0bb4\u0bcd'),
            ),
          ],
          itemHeight: null,
          decoration: widget.settingsCard
              ? const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                )
              : InputDecoration(
                  labelText: context.l10n.language,
                  prefixIcon: const Icon(Icons.language),
                  border: const OutlineInputBorder(),
                ),
          items: [
            AccessibleDropdownMenuItem(value: 'en', child: Text('English')),
            AccessibleDropdownMenuItem(value: 'si', child: Text('සිංහල')),
            AccessibleDropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
          ],
          onChanged: _saving ? null : (code) => _save(service, code),
        );
        if (!widget.settingsCard) return dropdown;
        final hc = context.isHighContrast;
        final large = context.hasLargeTargets;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: large ? 16 : 14,
          ),
          decoration: BoxDecoration(
            color: hc ? Colors.white : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: hc ? Border.all(color: Colors.black, width: 2) : null,
            boxShadow: hc
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: large ? 40 : 34,
                height: large ? 40 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hc
                      ? const Color(0xFFE5E5E5)
                      : AppColors.primaryContainer.withValues(alpha: 0.08),
                  border: hc
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: large ? 20 : 18,
                  color: context.subtextColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.language,
                      style: TextStyle(
                        fontSize: large ? 17 : 15,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    dropdown,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(LanguagePreferencesService service, String? code) async {
    if (code == null) return;
    setState(() => _saving = true);
    try {
      await service.setLanguage(code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.languageSaveFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _revision++;
        });
      }
    }
  }
}
