/// Reviewed catalogue contracts. No tariff is inferred from time, kilometres or
/// number of stops. Construction must use acknowledged trusted catalogue data;
/// this contract alone does not grant a client authority to publish fares.
class FareSelection {
  const FareSelection({
    required this.routePatternId,
    required this.serviceClass,
    required this.boardingOccurrenceId,
    required this.alightingOccurrenceId,
    required this.boardingAt,
  });
  final String routePatternId,
      serviceClass,
      boardingOccurrenceId,
      alightingOccurrenceId;
  final DateTime boardingAt;
}

class TariffFareQuote {
  const TariffFareQuote({
    required this.amountMinor,
    required this.tariffId,
    required this.tariffVersion,
    required this.mappingId,
    required this.mappingVersion,
    required this.source,
    required this.serviceDate,
    required this.routePatternId,
    required this.serviceClass,
    required this.boardingOccurrenceId,
    required this.alightingOccurrenceId,
  });
  final int amountMinor;
  final String tariffId, tariffVersion, mappingId, mappingVersion, serviceDate;
  final String routePatternId,
      serviceClass,
      boardingOccurrenceId,
      alightingOccurrenceId;
  final Uri source;
  String get currency => 'LKR';
  factory TariffFareQuote.fromMap(Map<String, dynamic> value) {
    final amount = value['amountMinor'];
    if (value['currency'] != 'LKR' ||
        amount is! int ||
        amount <= 0 ||
        amount > 100000000) {
      throw const FormatException('Invalid fare quote');
    }
    return TariffFareQuote(
      amountMinor: amount,
      tariffId: _text(value['tariffId']),
      tariffVersion: _text(value['tariffVersion']),
      mappingId: _text(value['mappingId']),
      mappingVersion: _text(value['mappingVersion']),
      source: _source(value['source']),
      serviceDate: _day(value['serviceDate']),
      routePatternId: _text(value['routePatternId']),
      serviceClass: _text(value['serviceClass']),
      boardingOccurrenceId: _text(value['boardingOccurrenceId']),
      alightingOccurrenceId: _text(value['alightingOccurrenceId']),
    );
  }
  Map<String, dynamic> toMap() => {
    'amountMinor': amountMinor,
    'currency': currency,
    'tariffId': tariffId,
    'tariffVersion': tariffVersion,
    'mappingId': mappingId,
    'mappingVersion': mappingVersion,
    'source': source.toString(),
    'serviceDate': serviceDate,
    'routePatternId': routePatternId,
    'serviceClass': serviceClass,
    'boardingOccurrenceId': boardingOccurrenceId,
    'alightingOccurrenceId': alightingOccurrenceId,
  };
}

String _text(dynamic value) {
  if (value is! String || value.trim().isEmpty || value.length > 500) {
    throw const FormatException('Invalid fare catalogue text');
  }
  return value;
}

String _day(dynamic value) {
  final text = _text(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
    throw const FormatException('Invalid fare effective date');
  }
  final date = DateTime.tryParse(text);
  if (date == null || date.toIso8601String().substring(0, 10) != text) {
    throw const FormatException('Invalid fare effective date');
  }
  return text;
}

Uri _source(dynamic value) {
  final uri = Uri.tryParse(_text(value));
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const FormatException('Invalid tariff source');
  }
  return uri;
}

class ReviewedFareTable {
  ReviewedFareTable._(
    this.id,
    this.version,
    this.routePatternId,
    this.serviceClass,
    this.effectiveFrom,
    this.effectiveUntil,
    this.source,
    this.amounts,
  );
  final String id,
      version,
      routePatternId,
      serviceClass,
      effectiveFrom,
      effectiveUntil;
  final Uri source;

  /// Directed fare matrix. Keys are authority stages, not stop indices.
  final Map<String, Map<String, int>> amounts;
  factory ReviewedFareTable.fromMap(String id, Map<String, dynamic> value) {
    if (value['reviewed'] != true || value['currency'] != 'LKR') {
      throw const FormatException('Unreviewed or unsupported fare table');
    }
    final start = _day(value['effectiveFrom']),
        end = _day(value['effectiveUntil']);
    if (start.compareTo(end) > 0 ||
        value['amounts'] is! Map ||
        (value['amounts'] as Map).isEmpty) {
      throw const FormatException('Invalid fare table');
    }
    final matrix = <String, Map<String, int>>{};
    for (final row in (value['amounts'] as Map).entries) {
      final from = _text(row.key);
      if (row.value is! Map || (row.value as Map).isEmpty) {
        throw const FormatException('Invalid fare matrix');
      }
      final values = <String, int>{};
      for (final cell in (row.value as Map).entries) {
        final amount = cell.value;
        if (amount is! int || amount <= 0 || amount > 100000000) {
          throw const FormatException('Invalid minor-unit fare');
        }
        values[_text(cell.key)] = amount;
      }
      matrix[from] = Map.unmodifiable(values);
    }
    return ReviewedFareTable._(
      _text(id),
      _text(value['version']),
      _text(value['routePatternId']),
      _text(value['serviceClass']),
      start,
      end,
      _source(value['source']),
      Map.unmodifiable(matrix),
    );
  }
}

class ReviewedFareMapping {
  ReviewedFareMapping._(
    this.id,
    this.version,
    this.tariffId,
    this.routePatternId,
    this.serviceClass,
    this.effectiveFrom,
    this.effectiveUntil,
    this.occurrences,
    this.stageByOccurrence,
  );
  final String id,
      version,
      tariffId,
      routePatternId,
      serviceClass,
      effectiveFrom,
      effectiveUntil;

  /// Occurrence IDs permit loops with the same physical station appearing twice.
  final List<String> occurrences;
  final Map<String, String> stageByOccurrence;
  factory ReviewedFareMapping.fromMap(String id, Map<String, dynamic> value) {
    if (value['reviewed'] != true ||
        value['occurrences'] is! List ||
        value['stageByOccurrence'] is! Map) {
      throw const FormatException('Unreviewed or invalid fare mapping');
    }
    final start = _day(value['effectiveFrom']),
        end = _day(value['effectiveUntil']);
    final stops = (value['occurrences'] as List).map(_text).toList();
    final stages = <String, String>{
      for (final e in (value['stageByOccurrence'] as Map).entries)
        _text(e.key): _text(e.value),
    };
    if (start.compareTo(end) > 0 ||
        stops.length < 2 ||
        stops.toSet().length != stops.length ||
        stages.keys.any((s) => !stops.contains(s))) {
      throw const FormatException('Invalid fare occurrences');
    }
    return ReviewedFareMapping._(
      _text(id),
      _text(value['version']),
      _text(value['tariffId']),
      _text(value['routePatternId']),
      _text(value['serviceClass']),
      start,
      end,
      List.unmodifiable(stops),
      Map.unmodifiable(stages),
    );
  }
}

abstract final class TariffFare {
  /// Fail closed on absent/ambiguous mappings, overlaps, class/direction/date
  /// mismatch or missing matrix cells. Destination may be after midnight.
  static TariffFareQuote? quote(
    FareSelection selection, {
    required Iterable<ReviewedFareTable> tables,
    required Iterable<ReviewedFareMapping> mappings,
  }) {
    final civil = selection.boardingAt.toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final day = civil.toIso8601String().substring(0, 10);
    bool applies(
      String pattern,
      String serviceClass,
      String from,
      String until,
    ) =>
        selection.routePatternId == pattern &&
        selection.serviceClass == serviceClass &&
        from.compareTo(day) <= 0 &&
        until.compareTo(day) >= 0;
    final matching = mappings
        .where(
          (m) => applies(
            m.routePatternId,
            m.serviceClass,
            m.effectiveFrom,
            m.effectiveUntil,
          ),
        )
        .toList();
    if (matching.length != 1) return null;
    final mapping = matching.single;
    final from = mapping.occurrences.indexOf(selection.boardingOccurrenceId),
        to = mapping.occurrences.indexOf(selection.alightingOccurrenceId);
    if (from < 0 || to <= from) return null;
    final eligible = tables
        .where(
          (t) =>
              t.id == mapping.tariffId &&
              applies(
                t.routePatternId,
                t.serviceClass,
                t.effectiveFrom,
                t.effectiveUntil,
              ),
        )
        .toList();
    if (eligible.length != 1) return null;
    final tariff = eligible.single;
    final amount =
        tariff.amounts[mapping.stageByOccurrence[selection
            .boardingOccurrenceId]]?[mapping.stageByOccurrence[selection
            .alightingOccurrenceId]];
    if (amount == null) return null;
    return TariffFareQuote(
      amountMinor: amount,
      tariffId: tariff.id,
      tariffVersion: tariff.version,
      mappingId: mapping.id,
      mappingVersion: mapping.version,
      source: tariff.source,
      serviceDate: day,
      routePatternId: selection.routePatternId,
      serviceClass: selection.serviceClass,
      boardingOccurrenceId: selection.boardingOccurrenceId,
      alightingOccurrenceId: selection.alightingOccurrenceId,
    );
  }
}
