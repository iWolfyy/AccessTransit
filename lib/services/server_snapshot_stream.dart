import 'dart:async';

/// Cached/pending snapshots mean synchronization is in progress, not failure.
/// Never publishes them as trusted data. A bounded wait reports an unavailable
/// connection, and a later server snapshot can still recover the listener.
Stream<T> serverSnapshotStream<T>(
  Stream<T> source, {
  required bool Function(T) isVerified,
  Duration wait = const Duration(seconds: 15),
}) {
  late StreamController<T> output;
  StreamSubscription<T>? subscription;
  Timer? deadline;
  var waiting = false;
  void awaitingServer() {
    if (waiting) return;
    waiting = true;
    deadline = Timer(wait, () {
      output.addError(
        TimeoutException('Server verification unavailable.', wait),
      );
    });
  }

  output = StreamController<T>(
    onListen: () {
      awaitingServer();
      subscription = source.listen(
        (value) {
          if (!isVerified(value)) {
            awaitingServer();
            return;
          }
          deadline?.cancel();
          waiting = false;
          output.add(value);
        },
        onError: (Object error, StackTrace trace) {
          deadline?.cancel();
          waiting = false;
          output.addError(error, trace);
        },
        onDone: () {
          deadline?.cancel();
          output.close();
        },
      );
    },
    onCancel: () async {
      deadline?.cancel();
      await subscription?.cancel();
    },
  );
  return output.stream;
}
