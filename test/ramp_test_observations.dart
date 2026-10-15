import 'package:access_transit/data/seed_data.dart';
import 'package:access_transit/models/report.dart';
import 'package:access_transit/services/firestore_service.dart';

/// Explicit dated evidence for planning tests; runtime samples have no checks.
Future<void> recordWorkingRamps() async {
  for (final bus in SeedData.sampleBuses.where(
    (bus) => bus.hasRamp && bus.rampOk == true,
  )) {
    await FirestoreService(reportWriter: (_) async {}).createReport(
      Report(
        id: 'test-working-${bus.id}',
        targetType: 'bus',
        targetId: bus.id,
        problemType: 'Ramp Working',
        subCategory: 'Ramp Working',
        category: 'rampAccess',
        status: 'active',
        createdAt: DateTime.now(),
        userId: 'test-observer',
      ),
    );
  }
}
