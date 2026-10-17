import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public registration rejects admin before contacting Authentication',
    () async {
      await expectLater(
        AuthService().register(
          name: 'Attempt',
          email: 'attempt@example.test',
          password: 'unused',
          role: UserRole.admin,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'passengers and reporters share dashboard privileges, not operator access',
    () {
      expect(UserRole.passenger.usesPassengerDashboard, isTrue);
      expect(UserRole.contributor.usesPassengerDashboard, isTrue);
      expect(UserRole.operator.usesPassengerDashboard, isFalse);
      expect(UserRole.admin.usesPassengerDashboard, isFalse);
    },
  );
}
