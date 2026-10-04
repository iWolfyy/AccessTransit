import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../screens/community/community_screen.dart';
import '../../screens/journey/journey_search_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/profile/profile_screen.dart';

/// Shared navigation helpers for AccessTransit screens.
abstract final class AppNavigation {
  /// Returns to the root (Home) route.
  static void goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Opens Journey Search (Plan).
  static Future<void> openPlan(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JourneySearchScreen()),
    );
  }

  /// Opens the Community hub.
  static Future<void> openCommunity(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

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

  /// Shared bottom-nav handler used across push-screens that still reference
  /// navigation by label.
  ///
  /// [currentTab] is the tab for the screen the user is already on
  /// (`Home`, `Plan`, `Community`, or `Profile`).
  static void handleBottomNav(
    BuildContext context,
    String label, {
    String? currentTab,
    UserModel? profileUser,
    void Function(String message)? onUnsupported,
  }) {
    if (currentTab != null && label == currentTab) {
      return;
    }

    final shell = context.findAncestorStateOfType<MainShellState>();
    if (shell != null) {
      shell.switchToTab(label);
      return;
    }

    switch (label) {
      case 'Home':
        goHome(context);
        return;
      case 'Plan':
        openPlan(context);
        return;
      case 'Community':
        openCommunity(context);
        return;
      case 'Profile':
        openProfile(context, initialUser: profileUser);
        return;
      default:
        onUnsupported?.call('$label will be available soon.');
    }
  }
}
