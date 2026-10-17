import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report.dart';
import 'sample_test_mode.dart';

class ReportTarget {
  const ReportTarget(this.type, this.id);
  final String type, id;
  String get key => '$type/$id';
}

class SegmentReportPage {
  SegmentReportPage(List<Report> reports, {this.next})
    : reports = List.unmodifiable(reports);
  final List<Report> reports;
  final String? next;
}

class SegmentReports {
  Query<Map<String, dynamic>> query(
    ReportTarget target, {
    List<String>? stops,
  }) {
    if (!['bus', 'station'].contains(target.type) || target.id.isEmpty) {
      throw ArgumentError('Exact report target required');
    }
    var q = FirebaseFirestore.instance
        .collection(SampleTestMode.collection('reports'))
        .where('status', isEqualTo: 'active')
        .where('targetType', isEqualTo: target.type);
    q = stops == null
        ? q.where('targetId', isEqualTo: target.id)
        : q.where('targetId', whereIn: stops);
    return q.orderBy(FieldPath.documentId, descending: true);
  }

  Stream<SegmentReportPage> page(ReportTarget target, {String? after}) {
    var q = query(target);
    if (after != null) q = q.startAfter([after]);
    return q.limit(21).snapshots(includeMetadataChanges: true).map((s) {
      _acknowledged(s);
      final docs = s.docs.take(20).toList();
      return SegmentReportPage(
        docs.map(Report.fromFirestore).toList(),
        next: s.docs.length > 20 ? docs.last.id : null,
      );
    });
  }

  /// Bounded preview: four records per bus/30-stop query, never a whole feed.
  Stream<List<Report>> preview(String busId, List<String> stops) {
    final ids = stops.where((id) => id.isNotEmpty).toSet().toList();
    if (busId.isEmpty || ids.length > 300) {
      return Stream.error(StateError('Invalid selected segment'));
    }
    final queries = [
      query(ReportTarget('bus', busId)),
      for (var i = 0; i < ids.length; i += 30)
        query(
          ReportTarget('station', ids[i]),
          stops: ids.skip(i).take(30).toList(),
        ),
    ];
    late StreamController<List<Report>> controller;
    final subscriptions = <StreamSubscription>[];
    final values = <int, List<Report>>{};
    controller = StreamController<List<Report>>(
      onListen: () {
        for (var i = 0; i < queries.length; i++) {
          final index = i;
          subscriptions.add(
            queries[i]
                .limit(4)
                .snapshots(includeMetadataChanges: true)
                .listen(
                  (s) {
                    try {
                      _acknowledged(s);
                      values[index] = s.docs.map(Report.fromFirestore).toList();
                      if (values.length == queries.length) {
                        controller.add([for (final v in values.values) ...v]);
                      }
                    } catch (e, st) {
                      values.remove(index);
                      controller.addError(e, st);
                    }
                  },
                  onError: (Object e, StackTrace st) {
                    values.remove(index);
                    controller.addError(e, st);
                  },
                ),
          );
        }
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  void _acknowledged(QuerySnapshot<Map<String, dynamic>> s) {
    if (s.metadata.isFromCache || s.metadata.hasPendingWrites) {
      throw StateError('Connect to refresh scoped reports');
    }
  }
}
