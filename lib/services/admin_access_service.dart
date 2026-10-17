import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  Stream<String?> get userIds =>
      FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
  Future<bool> check(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid != uid) return false;
    final token = await user!.getIdTokenResult(true);
    return FirebaseAuth.instance.currentUser?.uid == uid &&
        token.claims?['admin'] == true;
  }
}
