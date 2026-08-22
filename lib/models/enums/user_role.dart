/// Application roles stored on the Firestore user profile.
enum UserRole {
  passenger('passenger'),
  contributor('contributor');

  const UserRole(this.value);

  final String value;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.passenger,
    );
  }
}
