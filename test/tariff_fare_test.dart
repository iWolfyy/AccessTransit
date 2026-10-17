import 'package:access_transit/logic/tariff_fare.dart';
import 'package:flutter_test/flutter_test.dart';

// Fictional arithmetic fixtures; these are NOT imported Sri Lankan tariffs.
Map<String, dynamic> table({
  String pattern = 'r-out',
  String serviceClass = 'normal',
  String start = '2026-10-01',
  String end = '2026-10-31',
}) => {
  'reviewed': true,
  'currency': 'LKR',
  'version': 'test-v1',
  'routePatternId': pattern,
  'serviceClass': serviceClass,
  'effectiveFrom': start,
  'effectiveUntil': end,
  'source': 'https://authority.example/fictional-test-only',
  'amounts': {
    'stage-A': {'stage-B': 12345, 'stage-C': 25000},
    'stage-B': {'stage-C': 9900},
  },
};
Map<String, dynamic> mapping() => {
  'reviewed': true,
  'version': 'mapping-test-v1',
  'tariffId': 'tariff',
  'routePatternId': 'r-out',
  'serviceClass': 'normal',
  'effectiveFrom': '2026-10-01',
  'effectiveUntil': '2026-10-31',
  'occurrences': ['station-a-first', 'station-b', 'station-a-return'],
  'stageByOccurrence': {
    'station-a-first': 'stage-A',
    'station-b': 'stage-B',
    'station-a-return': 'stage-C',
  },
};
FareSelection selection({
  String pattern = 'r-out',
  String serviceClass = 'normal',
  String from = 'station-a-first',
  String to = 'station-b',
  DateTime? at,
}) => FareSelection(
  routePatternId: pattern,
  serviceClass: serviceClass,
  boardingOccurrenceId: from,
  alightingOccurrenceId: to,
  boardingAt: at ?? DateTime.utc(2026, 10, 16, 4, 30),
);
TariffFareQuote? quote(
  FareSelection selected, {
  List<ReviewedFareTable>? tables,
  List<ReviewedFareMapping>? mappings,
}) => TariffFare.quote(
  selected,
  tables: tables ?? [ReviewedFareTable.fromMap('tariff', table())],
  mappings: mappings ?? [ReviewedFareMapping.fromMap('mapping', mapping())],
);
void main() {
  test('explicit directed matrix produces integer minor units and versioned selected-segment provenance', () {
    final q = quote(selection())!;
    expect(q.amountMinor, 12345);
    expect(q.currency, 'LKR');
    expect(q.tariffVersion, 'test-v1');
    expect(q.mappingVersion, 'mapping-test-v1');
    expect(q.serviceDate, '2026-10-16');
    expect(q.toMap()['boardingOccurrenceId'], 'station-a-first');
    expect(
      q.toMap()['source'],
      'https://authority.example/fictional-test-only',
    );
    expect(
      quote(selection(from: 'station-b', to: 'station-a-return'))!.amountMinor,
      9900,
    );
    expect(quote(selection(to: 'station-a-return'))!.amountMinor, 25000);
    // The listed through fare is deliberately not the sum of segment cells.
    expect(q.amountMinor + 9900, isNot(25000));
  });
  test('loop occurrences and direction are exact; no physical-stop or reverse inference', () {
    expect(quote(selection(from: 'station-a-return', to: 'station-b')), isNull);
    expect(quote(selection(from: 'station-a', to: 'station-b')), isNull);
    expect(quote(selection(pattern: 'r-in')), isNull);
    expect(quote(selection(serviceClass: 'luxury')), isNull);
    expect(quote(selection(from: 'station-b', to: 'station-b')), isNull);
  });
  test('effective dates use Colombo boarding date at exact UTC boundaries and ignore device timezone', () {
    expect(quote(selection(at: DateTime.utc(2026, 9, 30, 18, 29, 59))), isNull);
    expect(quote(selection(at: DateTime.utc(2026, 9, 30, 18, 30))), isNotNull);
    expect(
      quote(selection(at: DateTime.utc(2026, 10, 31, 18, 29, 59))),
      isNotNull,
    );
    expect(quote(selection(at: DateTime.utc(2026, 10, 31, 18, 30))), isNull);
    expect(
      quote(selection(at: DateTime.parse('2026-10-01T00:00:00+05:30')))!
          .serviceDate,
      '2026-10-01',
    );
  });
  test('missing mapping/matrix cells and overlapping reviewed versions fail closed', () {
    expect(quote(selection(), mappings: []), isNull);
    expect(quote(selection(), tables: []), isNull);
    final m = mapping();
    m['stageByOccurrence'] = {'station-a-first': 'stage-A'};
    expect(
      quote(selection(), mappings: [ReviewedFareMapping.fromMap('mapping', m)]),
      isNull,
    );
    final t = table();
    t['amounts'] = {
      'stage-A': {'stage-C': 25000},
    };
    expect(
      quote(selection(), tables: [ReviewedFareTable.fromMap('tariff', t)]),
      isNull,
    );
    expect(
      quote(
        selection(),
        tables: [
          ReviewedFareTable.fromMap('tariff', table()),
          ReviewedFareTable.fromMap('tariff', table()),
        ],
      ),
      isNull,
    );
    expect(
      quote(
        selection(),
        mappings: [
          ReviewedFareMapping.fromMap('m1', mapping()),
          ReviewedFareMapping.fromMap('m2', mapping()),
        ],
      ),
      isNull,
    );
  });
  test('catalogue parser rejects unreviewed, floating/zero/negative prices, invalid dates and untrusted source format', () {
    for (final changes in <Map<String, dynamic>>[
      {'reviewed': false},
      {'currency': 'USD'},
      {'source': 'http://example.com/tariff'},
      {'source': 'https://secret:password@example.com/tariff'},
      {'effectiveFrom': '2026-02-30'},
      {'effectiveFrom': '2026-11-01'},
      {'version': ''},
      {'amounts': {}},
      for (final amount in [0, -1, 123.45, 100000001])
        {
          'amounts': {
            'stage-A': {'stage-B': amount},
          },
        },
    ]) {
      expect(
        () => ReviewedFareTable.fromMap('tariff', {...table(), ...changes}),
        throwsFormatException,
      );
    }
    for (final changes in <Map<String, dynamic>>[
      {'reviewed': false},
      {
        'occurrences': ['same', 'same'],
      },
      {
        'stageByOccurrence': {'outside': 'stage-A'},
      },
    ]) {
      expect(
        () =>
            ReviewedFareMapping.fromMap('mapping', {...mapping(), ...changes}),
        throwsFormatException,
      );
    }
  });
  test('reviewed catalogue data is copied immutably before quoting', () {
    final raw = table(),
        map = mapping(),
        t = ReviewedFareTable.fromMap('tariff', raw),
        m = ReviewedFareMapping.fromMap('mapping', map);
    (raw['amounts'] as Map).clear();
    (map['occurrences'] as List).clear();
    expect(quote(selection(), tables: [t], mappings: [m])!.amountMinor, 12345);
    expect(() => t.amounts['stage-A']!['stage-B'] = 1, throwsUnsupportedError);
    expect(() => m.occurrences.add('extra'), throwsUnsupportedError);
  });
}
