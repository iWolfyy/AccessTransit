import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  static const String _avatarUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD84iJ2qrYpe7qg0m0trHUWlkCopN8eALXMnJb9EirKLXA3P7bgRWST6lj8gxkBxbQl-WcoXDArZZFjxuIM247yH7anq3D9hEAfbHGdg46TnmfDgZBMGwcfyMb1Xb1Xeq-onbyLjamygtvgDO9moliH5dT77hO6953V9LBDSNo_-Dtak8uPmyPEZDXHqtFfn274Ee9J-q6e54EGFv3o2SxYNIh1NwBq18p20C3vq3Fey--pQdLKicaXpQ';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFeatureSnackbar(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature will be available soon!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.name.isNotEmpty == true ? _user!.name : 'Alex Rivera';
    final roleText = _user?.role != null
        ? '${_user!.role.value.toUpperCase()} Commuter'
        : 'Inclusive Commuter';

    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBright,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
          onPressed: () => _showFeatureSnackbar('Navigation Menu'),
          tooltip: 'Open menu',
        ),
        centerTitle: true,
        title: const Text(
          'Access Transit',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showFeatureSnackbar('Profile Options'),
              child: ClipOval(
                child: Image.network(
                  _avatarUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.person, size: 18, color: AppColors.onPrimaryContainer),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header Section
                  _buildProfileHeader(displayName, roleText),
                  const SizedBox(height: 24),

                  // Stats Section (3 cards)
                  _buildStatsSection(),
                  const SizedBox(height: 24),

                  // Impact Card
                  _buildImpactCard(),
                  const SizedBox(height: 24),

                  // Badges & Achievements
                  _buildBadgesSection(),
                  const SizedBox(height: 24),

                  // Recent Activity
                  _buildRecentActivitySection(),
                  const SizedBox(height: 24),

                  // Account Settings & Links
                  _buildAccountSection(),
                  const SizedBox(height: 16),

                  if (widget.onLogout != null) ...[
                    OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String name, String role) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBright, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  _avatarUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 96,
                    height: 96,
                    color: AppColors.primaryContainer,
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBright, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.campaign_rounded,
            iconColor: AppColors.primary,
            count: '42',
            label: 'Reports',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            icon: Icons.verified_rounded,
            iconColor: AppColors.secondary,
            count: '128',
            label: 'Verifications',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem(
            icon: Icons.workspace_premium_rounded,
            iconColor: AppColors.tertiary,
            count: '12',
            label: 'Badges',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.diversity_3_rounded,
                  size: 140,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: AppColors.onPrimaryContainer,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Your Impact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.onPrimaryContainer,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Your reports have helped '),
                        TextSpan(
                          text: '1,200+',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' commuters this month.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badges & Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildBadgeCard(
                title: 'Early Adopter',
                icon: Icons.rocket_launch_rounded,
                iconColor: const Color(0xFFFFD700),
                borderColor: const Color(0xFFFFD700),
              ),
              const SizedBox(width: 12),
              _buildBadgeCard(
                title: 'Ramp Specialist',
                icon: Icons.accessible_forward_rounded,
                iconColor: const Color(0xFFC0C0C0),
                borderColor: const Color(0xFFC0C0C0),
              ),
              const SizedBox(width: 12),
              _buildBadgeCard(
                title: 'Elevator Scout',
                icon: Icons.elevator_rounded,
                iconColor: const Color(0xFFCD7F32),
                borderColor: const Color(0xFFCD7F32),
              ),
              const SizedBox(width: 12),
              _buildBadgeCard(
                title: 'Safety Sentinel',
                icon: Icons.security_rounded,
                iconColor: const Color(0xFFC0C0C0),
                borderColor: const Color(0xFFC0C0C0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Icons.check_circle_rounded,
          iconBgColor: AppColors.secondaryContainer,
          iconColor: AppColors.onSecondaryContainer,
          title: 'Verified Ramp on Bus 42',
          subtitle: '2 hours ago',
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: Icons.warning_rounded,
          iconBgColor: AppColors.errorContainer,
          iconColor: AppColors.onErrorContainer,
          title: 'Reported Elevator Out at Central',
          subtitle: 'Yesterday',
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAccountTile(
                icon: Icons.accessibility_new_rounded,
                title: 'Accessibility Preferences',
                onTap: () => _showFeatureSnackbar('Accessibility Preferences'),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainer),
              _buildAccountTile(
                icon: Icons.history_rounded,
                title: 'Route History',
                onTap: () => _showFeatureSnackbar('Route History'),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainer),
              _buildAccountTile(
                icon: Icons.bookmark_border_rounded,
                title: 'Saved Places',
                onTap: () => _showFeatureSnackbar('Saved Places'),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainer),
              _buildAccountTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () => _showFeatureSnackbar('Help & Support'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 64,
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
