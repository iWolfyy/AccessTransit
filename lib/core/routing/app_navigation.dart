import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../screens/profile/profile_screen.dart';

/// Shared navigation helpers for AccessTransit screens.
abstract final class AppNavigation {
  /// Opens the user profile screen.
  static Future<void> openProfile(
    BuildContext context, {
    UserModel? initialUser,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(initialUser: initialUser),
      ),
    );
  }
}
