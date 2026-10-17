/// Application roles stored on the Firestore user profile.
enum UserRole {
  passenger('passenger'),
  contributor('contributor'),
  operator('operator'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  /// Public registration records intent; operator approval is server-owned.
  bool get canSelfRegister => this != UserRole.admin;

  bool get usesPassengerDashboard =>
      this == UserRole.passenger || this == UserRole.contributor;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.passenger,
    );
  }
}
