import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/tariff_fare.dart';
import '../logic/journey_fare.dart';
import '../models/bus.dart';
import 'sample_test_mode.dart';
import 'admin_service.dart';
import '../logic/transit_time.dart';

/// One immutable reviewed publication binds a fare table/mapping to explicitly
/// reviewed physical vehicles. Route ID is the current directional pattern ID;
/// never infer a vehicle's service class from its public route number.
class FarePublication {
  FarePublication._(
    this.id,
    this.data,
    this.table,
    this.mapping,
    this.busIds,
    this.synthetic,
  );
  final String id;
  final Map<String, dynamic> data;
  final ReviewedFareTable table;
  final ReviewedFareMapping mapping;
  final List<String> busIds;
  final bool synthetic;
  static FarePublication parse(String id, Map<String, dynamic> input) {
    if (id.isEmpty ||
        id.contains('/') ||
        id.length > 128 ||
        utf8.encode(jsonEncode(input)).length > 120000) {
      throw const FormatException('Invalid fare publication');
    }
    final d = Map<String, dynamic>.from(jsonDecode(jsonEncode(input)) as Map);
    if (d['schemaVersion'] != 1 ||
        d['synthetic'] is! bool ||
        d['busIds'] is! List ||
        d['table'] is! Map ||
        d['mapping'] is! Map) {
      throw const FormatException('Invalid fare publication');
    }
    final buses = List<String>.from(d['busIds']);
    if (buses.isEmpty ||
        buses.length > 30 ||
        buses.toSet().length != buses.length ||
        buses.any((b) => b.isEmpty || b.contains('/') || b.length > 128)) {
      throw const FormatException('Select reviewed buses');
    }
    final table = ReviewedFareTable.fromMap(
      id,
      Map<String, dynamic>.from(d['table']),
    );
    final mapping = ReviewedFareMapping.fromMap(
      id,
      Map<String, dynamic>.from(d['mapping']),
    );
    if (table.amounts.values.fold<int>(0, (n, row) => n + row.length) > 500 ||
        mapping.occurrences.length > 300) {
      throw const FormatException(
        'Split this publication into smaller reviewed records',
      );
    }
    if (mapping.tariffId != id ||
        mapping.routePatternId != table.routePatternId ||
        mapping.serviceClass != table.serviceClass ||
        mapping.effectiveFrom.compareTo(table.effectiveFrom) < 0 ||
        mapping.effectiveUntil.compareTo(table.effectiveUntil) > 0) {
      throw const FormatException('Tariff/mapping applicability mismatch');
    }
    return FarePublication._(
      id,
      Map.unmodifiable(d),
      table,
      mapping,
      List.unmodifiable(buses),
      d['synthetic'],
    );
  }

  static TariffFareQuote? quote(
    List<FarePublication> values,
    Bus bus,
    String from,
    String to,
    DateTime at,
  ) {
    final day = at
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30))
        .toIso8601String()
        .substring(0, 10);
    final applicable = values
        .where(
          (v) =>
              v.synthetic == JourneyFare.prototypeEnabled &&
              v.busIds.contains(bus.id) &&
              v.table.routePatternId == bus.routeId &&
              v.mapping.effectiveFrom.compareTo(day) <= 0 &&
              v.mapping.effectiveUntil.compareTo(day) >= 0 &&
              _same(v.mapping.occurrences, bus.stops),
        )
        .toList();
    if (applicable.length != 1) return null;
    final v = applicable.single;
    return TariffFare.quote(
      FareSelection(
        routePatternId: v.table.routePatternId,
        serviceClass: v.table.serviceClass,
        boardingOccurrenceId: from,
        alightingOccurrenceId: to,
        boardingAt: at,
      ),
      tables: [v.table],
      mappings: [v.mapping],
    );
  }

  static bool _same(List<String> a, List<String> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);
}

class FareCatalogue {
  Stream<List<FarePublication>> watchBus(String id) async* {
    try {
      yield* FirebaseFirestore.instance
          .collection(SampleTestMode.collection('fare_publications'))
          .where('state', isEqualTo: 'published')
          .where('synthetic', isEqualTo: JourneyFare.prototypeEnabled)
          .where('busIds', arrayContains: id)
          .limit(21)
          .snapshots(includeMetadataChanges: true)
          .map((s) {
            if (s.metadata.isFromCache ||
                s.metadata.hasPendingWrites ||
                s.docs.length > 20) {
              return <FarePublication>[];
            }
            try {
              return s.docs
                  .map(
                    (d) => FarePublication.parse(d.id, {
                      for (final e in d.data().entries)
                        if (![
                          'updatedAt',
                          'updatedBy',
                          'reviewedAt',
                          'validFromAt',
                          'validUntilAt',
                        ].contains(e.key))
                          e.key: e.value,
                    }),
                  )
                  .toList();
            } catch (_) {
              return <FarePublication>[];
            }
          });
    } catch (_) {
      yield const [];
    }
  }
}

class AdminFareService {
  AdminFareService(this.repository);
  final AdminRepository repository;
  Future<void> publish(FarePublication publication, String reason) async {
    publication = FarePublication.parse(publication.id, publication.data);
    if (reason.trim().length < 10 ||
        reason.length > 2000 ||
        publication.synthetic != JourneyFare.prototypeEnabled) {
      throw const FormatException(
        'Review source, stages, class and effective dates; enter a review reason.',
      );
    }
    final route = (await repository.load('routes'))
        .where((r) => r.id == publication.table.routePatternId)
        .singleOrNull;
    if (route == null ||
        (!JourneyFare.prototypeEnabled &&
            (route.data['isDemo'] == true ||
                route.text('catalogueSource') != 'operator_catalogue')) ||
        route.data['deletionPending'] == true ||
        route.data['archived'] == true) {
      throw StateError('Route is unavailable');
    }
    final buses = await repository.load('buses');
    final changes = <AdminChange>[
      AdminChange('routes', route.id, route.data, route.data, checkOnly: true),
    ];
    for (final id in publication.busIds) {
      final bus = buses.where((b) => b.id == id).singleOrNull;
      if (bus == null ||
          (!JourneyFare.prototypeEnabled &&
              (bus.data['isDemo'] == true ||
                  bus.text('catalogueSource') != 'operator_catalogue')) ||
          bus.text('routeId') != route.id ||
          bus.data['deletionPending'] == true ||
          bus.text('catalogueRecordType') == 'published_timetable' ||
          !FarePublication._same(
            List<String>.from(bus.data['stops'] ?? []),
            publication.mapping.occurrences,
          )) {
        throw StateError(
          'A bus itinerary or route does not match the reviewed mapping',
        );
      }
      changes.add(
        AdminChange('buses', id, bus.data, bus.data, checkOnly: true),
      );
    }
    // The commit reads the target's expected absence, rejecting reused IDs and
    // concurrent publications atomically rather than loading the whole catalogue.
    changes.add(
      AdminChange('fare_publications', publication.id, null, {
        ...publication.data,
        'state': 'published',
        'busIds': publication.busIds,
        'synthetic': publication.synthetic,
        'schemaVersion': 1,
        'reviewReason': reason.trim(),
        'validFromAt': Timestamp.fromDate(
          TransitTime.instant(
            DateTime.parse(publication.mapping.effectiveFrom),
          ),
        ),
        'validUntilAt': Timestamp.fromDate(
          TransitTime.instant(
            DateTime.parse(publication.mapping.effectiveUntil)
                .add(const Duration(days: 1)),
          ),
        ),
      }),
    );
    await repository.commit(changes, 'fare_publish');
  }

  Future<void> archive(AdminRecord record, String reason) async {
    if (record.kind != 'fare_publications' ||
        record.text('state') != 'published' ||
        reason.trim().length < 10 ||
        reason.length > 2000) {
      throw const FormatException('Enter an archive reason');
    }
    await repository.commit([
      AdminChange(record.kind, record.id, record.data, {
        ...record.data,
        'state': 'archived',
        'archiveReason': reason.trim(),
      }),
    ], 'fare_archive');
  }
}
