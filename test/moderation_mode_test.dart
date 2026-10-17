import 'package:access_transit/services/moderation_mode.dart';
import 'package:flutter_test/flutter_test.dart';

ModerationConfiguration config({
  bool requested = true,
  bool local = false,
  bool debug = false,
  String origin = 'https://backend.example.org',
}) => ModerationConfiguration(
  requested: requested,
  localValidation: local,
  debug: debug,
  origin: origin,
);

void main() {
  test('main release and debug builds activate v2 with HTTPS, without emulator mode', () {
    for (final debug in [false, true]) {
      final c = config(debug: debug);
      expect(c.validate, returnsNormally);
      expect(c.enabled, true);
      expect(c.local, false);
      expect(c.apiOrigin.toString(), 'https://backend.example.org');
    }
  });
  test('main activation rejects missing, HTTP or non-origin endpoints', () {
    for (final origin in [
      '',
      'http://10.0.2.2:8787',
      'http://backend.example.org',
      'https://user:password@backend.example.org',
      'https://backend.example.org/v2',
      'https://backend.example.org?project=other',
      'https://backend.example.org#fragment',
    ]) {
      final c = config(origin: origin);
      expect(c.enabled, false, reason: origin);
      expect(c.local, false);
      expect(c.validate, throwsStateError, reason: origin);
    }
  });
  test('emulator endpoint is fixed and restricted to explicit debug tests', () {
    final local = config(
      local: true,
      debug: true,
      origin: 'https://ignored.example.org',
    );
    expect(local.validate, returnsNormally);
    expect(local.enabled, true);
    expect(local.apiOrigin.toString(), 'http://10.0.2.2:8787');
    final release = config(local: true);
    expect(release.enabled, false);
    expect(release.validate, throwsStateError);
  });
  test('real Firebase localhost is debug-only, exact endpoint and separate from demo', () {
    const c = ModerationConfiguration(
      requested: true,
      localValidation: false,
      debug: true,
      origin: 'https://ignored.example.org',
      localApi: true,
    );
    expect(c.validate, returnsNormally);
    expect(c.enabled, true);
    expect(c.local, false);
    expect(c.sharedLocal, true);
    expect(c.apiOrigin.toString(), 'http://10.0.2.2:8788');
    for (final value in [
      'http://10.0.2.2:8787',
      'http://127.0.0.1:8788',
      'http://10.0.2.2:8788/path',
      'http://10.0.2.2:8788?scope=sample',
      'http://other.test:8788',
    ]) {
      expect(c.acceptsOrigin(Uri.parse(value)), false, reason: value);
    }
    expect(c.acceptsOrigin(c.apiOrigin), true);
    const release = ModerationConfiguration(
      requested: true,
      localValidation: false,
      debug: false,
      origin: 'https://valid.example.org',
      localApi: true,
    );
    expect(release.enabled, false);
    expect(release.acceptsOrigin(Uri.parse('http://10.0.2.2:8788')), false);
    expect(release.validate, throwsStateError);
    const mixed = ModerationConfiguration(
      requested: true,
      localValidation: true,
      debug: true,
      origin: '',
      localApi: true,
    );
    expect(mixed.enabled, false);
    expect(mixed.validate, throwsStateError);
  });
  test(
    'a flag is required and an unused configuration does not activate v2',
    () {
      for (final c in [
        config(requested: false),
        config(requested: false, origin: ''),
      ]) {
        expect(c.validate, returnsNormally);
        expect(c.enabled, false);
        expect(c.local, false);
      }
    },
  );
}
