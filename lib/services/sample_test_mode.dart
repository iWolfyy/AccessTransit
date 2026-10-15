/// Shared-project rehearsal data, isolated from the sourced transit catalogue.
/// Mode changes require restarting with the selected build flag, so listeners
/// and in-memory state cannot cross environments during an active operation.
abstract final class SampleTestMode {
  static const enabled = bool.fromEnvironment('SAMPLE_TEST');
  static const prefix = enabled ? 'sample_test/shared/' : '';
  static String collection(String name) => '$prefix$name';
  static String storage(String key) => enabled ? 'sample_test_$key' : key;
  static const notice =
      'SAMPLE / TEST MODE — fictional vehicles, reports, equipment and GPS. '
      'Not for travel decisions.';
}
