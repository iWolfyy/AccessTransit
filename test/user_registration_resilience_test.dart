import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Registration and UserService Resilience Tests', () {
    test('UserModel.fromAuth creates a complete user profile model', () {
      final user = UserModel.fromAuth(
        uid: 'user_test_123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+94771234567',
        role: UserRole.passenger,
      );

      expect(user.uid, equals('user_test_123'));
      expect(user.name, equals('Jane Doe'));
      expect(user.email, equals('jane@example.com'));
      expect(user.phone, equals('+94771234567'));
      expect(user.role, equals(UserRole.passenger));

      final map = user.toMap(isCreate: true);
      expect(map['uid'], equals('user_test_123'));
      expect(map['name'], equals('Jane Doe'));
      expect(map['email'], equals('jane@example.com'));
      expect(map['role'], equals('passenger'));
    });

    test('UserService safely caches user when Firestore is unavailable', () async {
      final userService = UserService();

      final user = UserModel.fromAuth(
        uid: 'user_fallback_456',
        name: 'John Driver',
        email: 'john.driver@example.com',
        role: UserRole.operator,
      );

      // Should not throw even when Firebase is not initialized
      await userService.createUser(user);

      // Should retrieve user from in-memory fallback
      final retrieved = await userService.getUser('user_fallback_456');
      expect(retrieved, isNotNull);
      expect(retrieved!.uid, equals('user_fallback_456'));
      expect(retrieved.name, equals('John Driver'));
      expect(retrieved.role, equals(UserRole.operator));

      final exists = await userService.userExists('user_fallback_456');
      expect(exists, isTrue);

      final notExists = await userService.userExists('non_existent_uid');
      expect(notExists, isFalse);
    });

    test('UserService updateUser updates cached user', () async {
      final userService = UserService();

      final user = UserModel.fromAuth(
        uid: 'user_update_789',
        name: 'Initial Name',
        email: 'test@example.com',
      );

      await userService.createUser(user);

      final updated = user.copyWith(name: 'Updated Name');
      await userService.updateUser(updated);

      final retrieved = await userService.getUser('user_update_789');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Updated Name'));
    });
  });
}
