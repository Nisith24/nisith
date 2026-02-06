import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/ui/auth_screen.dart';
import '../../features/mcq/ui/deck_screen.dart';
import '../../features/learn/ui/learn_screen.dart';
import '../../features/settings/ui/profile_screen.dart';
import '../../features/stats/ui/analytics_screen.dart';
import '../../features/shared/widgets/scaffold_with_nav.dart';
import '../../features/bookmarks/ui/bookmarks_screen.dart';

/// App router provider - matches React Native Expo Router structure
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.user != null;
      final isGoingToAuth = state.matchedLocation == '/auth';

      // Not logged in and not going to auth -> redirect to auth
      if (!isLoggedIn && !isGoingToAuth) {
        return '/auth';
      }

      // Logged in but going to auth -> redirect to home
      if (isLoggedIn && isGoingToAuth) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth route (no shell)
      // Auth route (no shell)
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Bookmarks route
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),

      // Main shell with floating nav
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithFloatingNav(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeckScreen(),
            ),
          ),
          GoRoute(
            path: '/learn',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LearnScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
