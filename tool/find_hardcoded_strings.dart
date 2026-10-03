// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('Error: lib/ directory not found.');
    return;
  }

  final rawTextPattern = RegExp(r'''Text\s*\(\s*['"]([^'"]+)['"]''');
  final paramPattern = RegExp(
      r'''(labelText|hintText|errorText|title|tooltip|message):\s*['"]([^'"]+)['"]''');

  int totalViolations = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (entity.path.contains('app_localizations')) continue;

      final lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//') || line.trim().startsWith('import')) continue;

        if (rawTextPattern.hasMatch(line) || paramPattern.hasMatch(line)) {
          print('${entity.path}:${i + 1} -> ${line.trim()}');
          totalViolations++;
        }
      }
    }
  }

  print('\n--------------------------------------------------');
  print('Total hardcoded string violations found: $totalViolations');
  print('--------------------------------------------------');
}
