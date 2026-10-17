import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bus.dart';
import 'sample_test_mode.dart';

class DriverRouteService {
  Stream<String?> get userIds =>
      FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);

  static List<Bus> eligibleBuses(Iterable<Bus> buses, String routeId) => buses
      .where(
        (b) =>
            routeId.isNotEmpty &&
            b.routeId == routeId &&
            !b.isPublishedTimetable,
      )
      .toList();

  /// Both the grant and referenced route must be acknowledged by the server.
  /// Cached authorization never leaves an operator workspace open.
  Stream<String?> watchRoute(String uid) {
    final db = FirebaseFirestore.instance;
    StreamSubscription? grant, route;
    late StreamController<String?> controller;
    var generation = 0;
    var cancelled = false;
    String? subscribedRoute;
    void emit(String? id) {
      if (!cancelled) controller.add(id);
    }

    controller = StreamController<String?>(
      onListen: () {
        grant = db
            .collection(SampleTestMode.collection('driver_route_assignments'))
            .doc(uid)
            .snapshots(includeMetadataChanges: true)
            .listen(
              (snapshot) async {
                final data = snapshot.data();
                final id = data?['routeId'];
                // A claim revision/review note cannot restart an active GPS UI
                // when the acknowledged route grant itself is unchanged.
                if (!snapshot.metadata.isFromCache &&
                    !snapshot.metadata.hasPendingWrites &&
                    data?['active'] == true &&
                    id == subscribedRoute &&
                    route != null) {
                  return;
                }
                final epoch = ++generation;
                subscribedRoute = null;
                emit(null);
                await route?.cancel();
                route = null;
                if (cancelled || epoch != generation) return;
                if (snapshot.metadata.isFromCache ||
                    snapshot.metadata.hasPendingWrites ||
                    data?['active'] != true ||
                    id is! String ||
                    id.isEmpty) {
                  return;
                }
                subscribedRoute = id;
                route = db
                    .collection(SampleTestMode.collection('routes'))
                    .doc(id)
                    .snapshots(includeMetadataChanges: true)
                    .listen(
                      (r) {
                        if (cancelled || epoch != generation) return;
                        emit(
                          !r.metadata.isFromCache &&
                                  !r.metadata.hasPendingWrites &&
                                  r.exists &&
                                  r.data()?['deletionPending'] != true &&
                                  r.data()?['isDemo'] != true &&
                                  r.data()?['catalogueSource'] != 'demo'
                              ? id
                              : null,
                        );
                      },
                      onError: (Object _) {
                        if (epoch == generation) emit(null);
                      },
                    );
              },
              onError: (Object _) {
                ++generation;
                subscribedRoute = null;
                unawaited(route?.cancel());
                emit(null);
              },
            );
      },
      onCancel: () async {
        cancelled = true;
        ++generation;
        await grant?.cancel();
        await route?.cancel();
      },
    );
    return controller.stream.distinct();
  }
}
