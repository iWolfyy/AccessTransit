import 'package:flutter/material.dart';

import '../l10n/localization_context.dart';
import '../services/language_preferences_service.dart';

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key, this.service});

  final LanguagePreferencesService? service;

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
      builder: (context, _) => DropdownButtonFormField<String>(
        key: ValueKey(
          '${service.userId}:${service.locale.languageCode}:$_revision',
        ),
        initialValue: service.locale.languageCode,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.l10n.language,
          prefixIcon: const Icon(Icons.language),
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'si', child: Text('සිංහල')),
          DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
        ],
        onChanged: _saving ? null : (code) => _save(service, code),
      ),
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
