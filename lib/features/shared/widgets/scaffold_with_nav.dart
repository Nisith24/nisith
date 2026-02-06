import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'floating_nav.dart';

/// Scaffold with floating navigation bar
class ScaffoldWithFloatingNav extends StatefulWidget {
  final Widget child;

  const ScaffoldWithFloatingNav({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithFloatingNav> createState() =>
      _ScaffoldWithFloatingNavState();
}

class _ScaffoldWithFloatingNavState extends State<ScaffoldWithFloatingNav> {
  int _currentIndex = 0;

  static const _routes = ['/', '/learn', '/profile', '/analytics'];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync current index with route
    final location = GoRouterState.of(context).uri.toString();
    final index = _routes.indexOf(location);
    if (index >= 0 && index != _currentIndex) {
      _currentIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          widget.child,

          // Floating nav
          FloatingNav(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}
