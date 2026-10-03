import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'community/community_screen.dart';
import 'home/home_screen.dart';
import 'journey/journey_search_screen.dart';
import 'profile/profile_screen.dart';

/// Shell wrapper that hosts the four main tabs with a persistent bottom nav bar.
///
/// Uses [IndexedStack] so that tab state is preserved when switching between
/// Home, Plan, Community, and Profile.  Sub-screens (details, confirmation,
/// live journey, etc.) are still pushed via [Navigator.push] and sit on top of
/// this shell — they do **not** show the bottom nav bar (Instagram pattern).
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialUser});

  /// Optional pre-loaded user to pass into [HomeScreen] / [ProfileScreen].
  final UserModel? initialUser;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<String> _tabLabels = [
    'Home',
    'Plan',
    'Community',
    'Profile',
  ];

  /// Public method so that external callers (e.g. deep-links) can switch tabs.
  void switchToTab(String label) {
    final idx = _tabLabels.indexOf(label);
    if (idx != -1 && idx != _currentIndex) {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(initialUser: widget.initialUser),
          const JourneySearchScreen(),
          const CommunityScreen(),
          ProfileScreen(initialUser: widget.initialUser),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : AppBottomNavBar(
              currentTab: _tabLabels[_currentIndex],
              onTabSelected: (label) {
                final idx = _tabLabels.indexOf(label);
                if (idx != -1) {
                  setState(() => _currentIndex = idx);
                }
              },
            ),
    );
  }
}
