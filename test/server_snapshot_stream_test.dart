import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:access_transit/services/server_snapshot_stream.dart';

void main() {
  testWidgets(
    'cache waits, verified snapshot recovers, idle server stays valid',
    (t) async {
      final source = StreamController<bool>();
      final values = <bool>[], errors = <Object>[];
      final sub = serverSnapshotStream(
        source.stream,
        isVerified: (v) => v,
      ).listen(values.add, onError: errors.add);
      source.add(false);
      await t.pump(const Duration(seconds: 1));
      expect(errors, isEmpty);
      expect(values, isEmpty);
      source.add(true);
      await t.pump();
      await t.pump(const Duration(seconds: 20));
      expect(values, [true]);
      expect(errors, isEmpty);
      source.add(false);
      await t.pump();
      await t.pump(const Duration(seconds: 15));
      expect(errors.single, isA<TimeoutException>());
      source.add(true);
      await t.pump();
      expect(values, [true, true]);
    unawaited(sub.cancel());
    await t.pump();
      unawaited(source.close());
    },
  );

  testWidgets(
    'permission errors surface immediately and cancellation clears deadline',
    (t) async {
      final source = StreamController<bool>();
      final errors = <Object>[];
      final sub = serverSnapshotStream(
        source.stream,
        isVerified: (v) => v,
      ).listen((_) {}, onError: errors.add);
      source.addError(StateError('permission-denied'));
      await t.pump();
      expect(errors.single, isA<StateError>());
      source.add(false);
      await t.pump();
    unawaited(sub.cancel());
      await t.pump(const Duration(seconds: 20));
      expect(errors, hasLength(1));
      unawaited(source.close());
    },
  );
}
