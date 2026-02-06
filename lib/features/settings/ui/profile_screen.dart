import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../stats/providers/user_stats_provider.dart';

/// ProfileScreen - Settings and user info
/// Matches React Native (tabs)/profile.tsx
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) {
        if (state.user == null) {
          return const Center(child: Text('Please sign in'));
        }

        final profile = state.userProfile;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),

                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardSurfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.user,
                            color: context.primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.displayName ?? 'User',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  const _StatsSection(),

                  const SizedBox(height: 24),

                  // Settings
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mock Test Config removed as requested

                  _SettingsTile(
                    icon: LucideIcons.moon,
                    title: 'Dark Mode',
                    trailing: Consumer(
                      builder: (context, ref, child) {
                        final themeMode = ref.watch(themeProvider);
                        return Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        );
                      },
                    ),
                  ),

                  _SettingsTile(
                    icon: LucideIcons.bookmark,
                    title: 'Bookmarks',
                    onTap: () => context.push('/bookmarks'),
                  ),

                  _SettingsTile(
                    icon: LucideIcons.barChart2,
                    title: 'Analytics',
                    onTap: () => context.push('/analytics'),
                  ),

                  const SizedBox(height: 24),

                  // Sign out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).signOut();
                      },
                      icon: Icon(LucideIcons.logOut, color: context.errorColor),
                      label: Text(
                        'Sign Out',
                        style: TextStyle(color: context.errorColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: context.errorColor.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(localUserStatsProvider);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Viewed',
            value: '${stats.viewedCount}',
            icon: LucideIcons.eye,
            color: context.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Bookmarked',
            value: '${stats.bookmarkCount}',
            icon: LucideIcons.bookmark,
            color: context.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '${stats.streakDays}',
            icon: LucideIcons.flame,
            color: context.errorColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: context.iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  LucideIcons.chevronRight,
                  color: context.iconColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
