import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isPressed = false;
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
      duration: const Duration(milliseconds: 350),
    );

    _widthAnimation = Tween<double>(begin: 50, end: 240).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(SpringConfigs.menuToggle),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
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
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 50,
            width: _widthAnimation.value,
            decoration: BoxDecoration(
              color: _isExpanded
                  ? (context.isDark
                      ? AppColors.dark.cardSurface
                      : AppColors.light.cardSurface)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              border: _isExpanded
                  ? Border.all(
                      color: context.isDark
                          ? AppColors.dark.border.withValues(alpha: 0.5)
                          : AppColors.light.border.withValues(alpha: 0.5),
                    )
                  : null,
              boxShadow: [
                if (_isExpanded)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Menu items
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Opacity(
                      opacity: _controller.value > 0.4
                          ? ((_controller.value - 0.4) / 0.6).clamp(0.0, 1.0)
                          : 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_navItems.length, (index) {
                          final item = _navItems[index];
                          final isSelected = index == widget.currentIndex;

                          // Staggered calculation based on animation controller
                          // Each item has a window in the 0.0 - 1.0 range
                          final start = 0.3 + (index * 0.1);
                          final itemValue = ((_controller.value - start) / 0.4)
                              .clamp(0.0, 1.0);

                          return Transform.translate(
                            offset: Offset(15 * (1 - itemValue), 0),
                            child: Transform.scale(
                              scale: 0.85 + 0.15 * itemValue,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (_isExpanded) _handleItemTap(index);
                                },
                                icon: Icon(
                                  item.icon,
                                  color: isSelected
                                      ? (context.isDark
                                          ? AppColors.dark.primary
                                          : AppColors.light.primary)
                                      : (context.isDark
                                          ? AppColors.dark.icon
                                          : AppColors.light.icon),
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Toggle button
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) => setState(() => _isPressed = false),
                    onTapCancel: () => setState(() => _isPressed = false),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _toggle();
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 100),
                      scale: _isPressed ? 0.92 : 1.0,
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? AppColors.dark.primary
                              : AppColors.light.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (!_isExpanded)
                              BoxShadow(
                                color: (context.isDark
                                        ? AppColors.dark.primary
                                        : AppColors.light.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Icon(
                            _isExpanded ? LucideIcons.x : LucideIcons.menu,
                            color: Colors.white,
                            size: 20,
                          ),
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
