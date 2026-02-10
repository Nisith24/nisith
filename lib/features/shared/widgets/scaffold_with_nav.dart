import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'floating_nav.dart';

/// Scaffold with floating navigation bar
class ScaffoldWithFloatingNav extends StatefulWidget {
  final Widget child;
  final GoRouterState state;

  const ScaffoldWithFloatingNav({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  State<ScaffoldWithFloatingNav> createState() =>
      _ScaffoldWithFloatingNavState();
}

class _ScaffoldWithFloatingNavState extends State<ScaffoldWithFloatingNav> {
  static const _routes = ['/', '/learn', '/profile', '/analytics'];

  void _onNavTap(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Use state passed from router instead of inherited widget lookup
    final location = widget.state.uri.toString();
    final index = _routes.indexOf(location);
    final currentIndex = index >= 0 ? index : 0;

    final hideNav =
        location.startsWith('/exam') || location.startsWith('/bookmarks');

    return Scaffold(
      body: Stack(
        children: [
          // Page content
          widget.child,

          // Floating nav
          if (!hideNav)
            FloatingNav(
              key: ValueKey('nav_${context.isDark}'),
              currentIndex: currentIndex,
              onTap: _onNavTap,
            ),
        ],
      ),
    );
  }
}
