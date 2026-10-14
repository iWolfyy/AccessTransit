// Firestore marks these interfaces sealed for production implementations;
// these test-only fakes exercise registration without a live Firebase project.
// ignore_for_file: subtype_of_sealed_class

import 'package:access_transit/models/enums/user_role.dart';
import 'package:access_transit/models/user_model.dart';
import 'package:access_transit/services/auth_service.dart';
import 'package:access_transit/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final existing = UserModel(
    uid: 'existing-user',
    name: 'Original Name',
    email: 'existing@example.com',
    phone: '+94771234567',
    role: UserRole.operator,
    createdAt: DateTime(2025, 1, 2),
    points: 250,
    reportsSubmitted: 12,
    verifiedCount: 7,
  );

  test(
    'repeat registration preserves the stored profile and routing role',
    () async {
      final storedData = {...existing.toMap(), 'customPreference': true};
      final db = _Firestore(storedData);
      final auth = _Auth(existing.uid, alreadyRegistered: true);
      final service = AuthService(
        auth: auth,
        userService: UserService(firestore: db),
      );

      final result = await service.register(
        name: 'Replacement Name',
        email: existing.email,
        password: 'correct-password',
        phone: '+94770000000',
        role: UserRole.passenger,
      );

      expect(auth.signInCalls, 1);
      expect(result.toMap(), existing.toMap());
      expect(db.data, storedData);
      expect(db.writeCount, 0);
      expect(auth.user.displayName, existing.name);
    },
  );

  test(
    'interrupted registration creates the missing profile only once',
    () async {
      final db = _Firestore(null);
      final auth = _Auth('interrupted-user', alreadyRegistered: true);
      final service = AuthService(
        auth: auth,
        userService: UserService(firestore: db),
      );

      final result = await service.register(
        name: 'New Operator',
        email: 'new@example.com',
        password: 'correct-password',
        role: UserRole.operator,
      );
      expect(result.name, 'New Operator');
      expect(result.role, UserRole.operator);
      expect(db.data!['createdAt'], isA<FieldValue>());
      expect(db.writeCount, 1);

      await service.register(
        name: 'Changed Name',
        email: 'new@example.com',
        password: 'correct-password',
        role: UserRole.passenger,
      );
      expect(db.writeCount, 1);
      expect(db.data!['name'], 'New Operator');
      expect(db.data!['role'], 'operator');
    },
  );

  test('new auth account creates its profile', () async {
    final db = _Firestore(null);
    final auth = _Auth('new-user');
    final result =
        await AuthService(
          auth: auth,
          userService: UserService(firestore: db),
        ).register(
          name: 'Passenger',
          email: 'new@example.com',
          password: 'password',
        );

    expect(result.uid, 'new-user');
    expect(auth.signInCalls, 0);
    expect(db.writeCount, 1);
    expect(db.data!['points'], 0);
  });

  test(
    'Firestore failure leaves the existing profile and auth name intact',
    () async {
      final db = _Firestore(existing.toMap())
        ..failure = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
      final auth = _Auth(existing.uid, alreadyRegistered: true);
      auth.user.displayName = existing.name;

      await expectLater(
        AuthService(
          auth: auth,
          userService: UserService(firestore: db),
        ).register(
          name: 'Replacement',
          email: existing.email,
          password: 'password',
        ),
        throwsA(isA<FirebaseException>()),
      );
      expect(db.data, existing.toMap());
      expect(db.writeCount, 0);
      expect(auth.user.displayName, existing.name);
    },
  );

  test(
    'wrong password cannot resume registration or write a profile',
    () async {
      final db = _Firestore(existing.toMap());
      final auth = _Auth(existing.uid, alreadyRegistered: true)
        ..signInFailure = FirebaseAuthException(code: 'invalid-credential');

      await expectLater(
        AuthService(
          auth: auth,
          userService: UserService(firestore: db),
        ).register(
          name: 'Replacement',
          email: existing.email,
          password: 'wrong-password',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(db.writeCount, 0);
      expect(db.data, existing.toMap());
    },
  );

  test(
    'fallback registration also preserves an existing cached profile',
    () async {
      final service = UserService();
      const profile = UserModel(
        uid: 'cached-user',
        name: 'Cached Profile',
        email: 'cached@example.com',
        role: UserRole.operator,
        points: 250,
        reportsSubmitted: 12,
        verifiedCount: 7,
      );
      await service.createUser(profile);
      final result = await service.createUser(
        UserModel.fromAuth(
          uid: profile.uid,
          name: 'Replacement',
          email: profile.email,
        ),
      );
      expect(result.toMap(), profile.toMap());
      expect((await service.getUser(profile.uid))!.toMap(), profile.toMap());
    },
  );
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(String uid, {this.alreadyRegistered = false}) : user = _User(uid);
  final _User user;
  final bool alreadyRegistered;
  int signInCalls = 0;
  FirebaseAuthException? signInFailure;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (alreadyRegistered) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    return _Credential(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    if (signInFailure != null) throw signInFailure!;
    return _Credential(user);
  }
}

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  String? displayName;
  @override
  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);
  @override
  final User user;
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.data);
  Map<String, dynamic>? data;
  int writeCount = 0;
  FirebaseException? failure;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection();

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    if (failure != null) throw failure!;
    return transactionHandler(_Transaction(this));
  }
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Document();
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Firestore db;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async => _Snapshot<T>(db.data as T?);

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    db.data = Map<String, dynamic>.from(data as Map<String, dynamic>);
    db.writeCount++;
    return this;
  }
}

class _Snapshot<T extends Object?> extends Fake implements DocumentSnapshot<T> {
  _Snapshot(this.value);
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
}
