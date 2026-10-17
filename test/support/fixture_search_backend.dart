import 'package:access_transit/logic/dated_boarding_matcher.dart';
import 'package:access_transit/logic/transit_time.dart';
import 'package:access_transit/models/service_run.dart';
import 'package:access_transit/services/firestore_service.dart';
import 'package:access_transit/services/transit_search_backend.dart';

/// Explicit test-only dated runs; runtime never infers physical operations.
class FixtureSearchBackend extends TransitSearchBackend {
  FixtureSearchBackend({DateTime Function()? now}) : now = now ?? DateTime.now;
  final DateTime Function() now;
  @override
  Stream<List<ServiceRun>> searchRuns(String id) => runs(id);
  @override
  Future<SearchTimeAnchor> synchronizeTime() async {
    final observed = now();
    return SearchTimeAnchor(
      observed,
      elapsed: () => now().difference(observed),
    );
  }

  @override
  Stream<List<ServiceRun>> runs(String busId) async* {
    final bus = await FirestoreService().getBusById(busId);
    if (bus == null || bus.stops.length < 2) {
      yield [];
      return;
    }
    final day = TransitTime.day(TransitTime.civil(now()));
    yield [
      for (final offset in [-1, 0, 1])
        if (DatedBoardingMatcher.publishedPlan(
              bus,
              bus.stops.first,
              bus.stops.last,
              day.add(Duration(days: offset)),
            )
            case final plan?)
          ServiceRun(
            id: '${bus.id}_${plan.departure.millisecondsSinceEpoch}',
            busId: bus.id,
            routeId: bus.routeId ?? '',
            routeNo: bus.routeNo,
            serviceDate: TransitTime.serviceDate(plan.departure),
            plannedDepartureAt: plan.departure,
            latestStartAt: plan.departure.add(ServiceRun.maximumLateStart),
            stopTimes: {
              for (final id in bus.stops)
                id: id == bus.stops.first
                    ? plan.departure
                    : DatedBoardingMatcher.publishedPlan(
                        bus,
                        bus.stops.first,
                        id,
                        day.add(Duration(days: offset)),
                      )!.arrival,
            },
          ),
    ];
  }
}
