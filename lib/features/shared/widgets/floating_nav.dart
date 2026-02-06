import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/spring_physics.dart';

/// Floating navigation bar with spring animation
/// Matches React Native (tabs)/_layout.tsx FloatingNav
class FloatingNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _rotationAnimation;

  static const _navItems = [
    _NavItem(icon: LucideIcons.layoutGrid, label: 'Deck', route: '/'),
    _NavItem(icon: LucideIcons.bookOpen, label: 'Learn', route: '/learn'),
    _NavItem(icon: LucideIcons.user, label: 'Profile', route: '/profile'),
    _NavItem(icon: LucideIcons.barChart2, label: 'Stats', route: '/analytics'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(begin: 60, end: 260).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(SpringConfigs.menuToggle),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleItemTap(int index) {
    widget.onTap(index);
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 60,
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppColors.dark.cardSurface
                  : AppColors.light.cardSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: context.isDark
                    ? AppColors.dark.border
                    : AppColors.light.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Menu items
                if (_isExpanded)
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isSelected = index == widget.currentIndex;

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 150 + index * 50),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(40 * (1 - value), 0),
                                child: Transform.scale(
                                  scale: 0.8 + 0.2 * value,
                                  child: IconButton(
                                    onPressed: () => _handleItemTap(index),
                                    icon: Icon(
                                      item.icon,
                                      color: isSelected
                                          ? (context.isDark
                                              ? AppColors.dark.primary
                                              : AppColors.light.primary)
                                          : (context.isDark
                                              ? AppColors.dark.icon
                                              : AppColors.light.icon),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),

                // Toggle button
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? AppColors.dark.primary
                            : AppColors.light.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          _isExpanded ? LucideIcons.x : LucideIcons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Custom spring curve
class _SpringCurve extends Curve {
  final SpringDescription spring;

  const _SpringCurve(this.spring);

  @override
  double transform(double t) {
    // Simplified spring approximation
    final damping =
        spring.damping / (2 * math.sqrt(spring.stiffness * spring.mass));
    final omega = math.sqrt(spring.stiffness / spring.mass);

    return 1 -
        math.exp(-damping * omega * t * 6) *
            math.cos(omega * math.sqrt(1 - damping * damping) * t * 6);
  }
}
