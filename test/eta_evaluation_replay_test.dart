import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/logic/eta_evaluation.dart';

void main() {
  test('replay bounded local ETA export and recompute summaries', () {
    const input = String.fromEnvironment('ETA_EVAL_INPUT');
    final file = File(
      input.isEmpty ? 'test/fixtures/eta-evaluation.local.json' : input,
    );
    expect(file.lengthSync(), lessThanOrEqualTo(700000));
    final ledger = EtaEvaluationLedger()..restore(file.readAsStringSync());
    final result = ledger.export();
    if (input.isEmpty) {
      expect(
        ledger.summaries().singleWhere(
          (r) => r['source'] == 'timetable',
        )['medianAbsoluteErrorSeconds'],
        120,
      );
      expect(
        ledger.summaries().singleWhere(
          (r) => r['source'] == 'geometry-timetable',
        )['p90AbsoluteErrorSeconds'],
        45,
      );
    }
    debugPrint(
      jsonEncode({
        'synthetic': true,
        'reference': result['reference'],
        'counts': result['counts'],
        'summaries': result['summaries'],
      }),
    );
  });
}
