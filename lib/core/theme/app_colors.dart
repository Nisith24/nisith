import 'package:flutter/material.dart';

/// App colors matching React Native constants/theme.ts
class AppColors {
  // Light theme colors
  static const light = LightColors();

  // Dark theme colors
  static const dark = DarkColors();
}

abstract class AppThemeColors {
  Color get text;
  Color get textSecondary;
  Color get background;
  Color get cardSurface;
  Color get tint;
  Color get border;
  Color get icon;
  Color get primary;
  Color get success;
  Color get successBg;
  Color get error;
  Color get errorBg;
  Color get warning;
  Color get warningBg;
  Color get tabIconDefault;
  Color get tabIconSelected;
  Color get optionIndex;
  Color get optionBorder;
  Color get headerTitle;
  Color get cardShadow;
}

class LightColors implements AppThemeColors {
  const LightColors();

  @override
  Color get text => const Color(0xFF1e293b);
  @override
  Color get textSecondary => const Color(0xFF64748b);
  @override
  Color get background => const Color(0xFFf8fafc);
  @override
  Color get cardSurface => const Color(0xFFffffff);
  @override
  Color get tint => const Color(0xFF0a7ea4);
  @override
  Color get border => const Color(0xFFe2e8f0);
  @override
  Color get icon => const Color(0xFF64748b);
  @override
  Color get primary => const Color(0xFF6366f1);
  @override
  Color get success => const Color(0xFF22c55e);
  @override
  Color get successBg => const Color(0xFFf0fdf4);
  @override
  Color get error => const Color(0xFFef4444);
  @override
  Color get errorBg => const Color(0xFFfef2f2);
  @override
  Color get warning => const Color(0xFFf59e0b);
  @override
  Color get warningBg => const Color(0xFFfffbeb);
  @override
  Color get tabIconDefault => const Color(0xFF94a3b8);
  @override
  Color get tabIconSelected => const Color(0xFF6366f1);
  @override
  Color get optionIndex => const Color(0xFFf1f5f9);
  @override
  Color get optionBorder => const Color(0xFFe2e8f0);
  @override
  Color get headerTitle => const Color(0xFF0f172a);
  @override
  Color get cardShadow => const Color(0xFF000000);
}

class DarkColors implements AppThemeColors {
  const DarkColors();

  @override
  Color get text => const Color(0xFFf1f5f9);
  @override
  Color get textSecondary => const Color(0xFF94a3b8);
  @override
  Color get background => const Color(0xFF020617);
  @override
  Color get cardSurface => const Color(0xFF1e293b);
  @override
  Color get tint => const Color(0xFFffffff);
  @override
  Color get border => const Color(0xFF334155);
  @override
  Color get icon => const Color(0xFF94a3b8);
  @override
  Color get primary => const Color(0xFF818cf8);
  @override
  Color get success => const Color(0xFF4ade80);
  @override
  Color get successBg => const Color(0xFF052e16);
  @override
  Color get error => const Color(0xFFf87171);
  @override
  Color get errorBg => const Color(0xFF450a0a);
  @override
  Color get warning => const Color(0xFFfbbf24);
  @override
  Color get warningBg => const Color(0xFF451a03);
  @override
  Color get tabIconDefault => const Color(0xFF64748b);
  @override
  Color get tabIconSelected => const Color(0xFF818cf8);
  @override
  Color get optionIndex => const Color(0xFF334155);
  @override
  Color get optionBorder => const Color(0xFF334155);
  @override
  Color get headerTitle => const Color(0xFFf8fafc);
  @override
  Color get cardShadow => const Color(0xFF000000);
}

/// Extension to get colors based on brightness
extension AppColorsExtension on BuildContext {
  LightColors get lightColors => AppColors.light;
  DarkColors get darkColors => AppColors.dark;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get textColor => isDark ? darkColors.text : lightColors.text;
  Color get textSecondaryColor =>
      isDark ? darkColors.textSecondary : lightColors.textSecondary;
  Color get backgroundColor =>
      isDark ? darkColors.background : lightColors.background;
  Color get cardSurfaceColor =>
      isDark ? darkColors.cardSurface : lightColors.cardSurface;
  Color get borderColor => isDark ? darkColors.border : lightColors.border;
  Color get primaryColor => isDark ? darkColors.primary : lightColors.primary;
  Color get successColor => isDark ? darkColors.success : lightColors.success;
  Color get successBgColor =>
      isDark ? darkColors.successBg : lightColors.successBg;
  Color get errorColor => isDark ? darkColors.error : lightColors.error;
  Color get errorBgColor => isDark ? darkColors.errorBg : lightColors.errorBg;
  Color get warningColor => isDark ? darkColors.warning : lightColors.warning;
  Color get warningBgColor =>
      isDark ? darkColors.warningBg : lightColors.warningBg;
  Color get iconColor => isDark ? darkColors.icon : lightColors.icon;
}
