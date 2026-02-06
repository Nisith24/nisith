import 'package:flutter/material.dart';

/// App colors matching React Native constants/theme.ts
class AppColors {
  // Light theme colors
  static const light = LightColors();

  // Dark theme colors
  static const dark = DarkColors();
}

class LightColors {
  const LightColors();

  Color get text => const Color(0xFF1e293b);
  Color get textSecondary => const Color(0xFF64748b);
  Color get background => const Color(0xFFf8fafc);
  Color get cardSurface => const Color(0xFFffffff);
  Color get tint => const Color(0xFF0a7ea4);
  Color get border => const Color(0xFFe2e8f0);
  Color get icon => const Color(0xFF64748b);
  Color get primary => const Color(0xFF6366f1);
  Color get success => const Color(0xFF22c55e);
  Color get successBg => const Color(0xFFf0fdf4);
  Color get error => const Color(0xFFef4444);
  Color get errorBg => const Color(0xFFfef2f2);
  Color get warning => const Color(0xFFf59e0b);
  Color get warningBg => const Color(0xFFfffbeb);
  Color get tabIconDefault => const Color(0xFF94a3b8);
  Color get tabIconSelected => const Color(0xFF6366f1);
  Color get optionIndex => const Color(0xFFf1f5f9);
  Color get optionBorder => const Color(0xFFe2e8f0);
  Color get headerTitle => const Color(0xFF0f172a);
  Color get cardShadow => const Color(0xFF000000);
}

class DarkColors {
  const DarkColors();

  Color get text => const Color(0xFFf1f5f9);
  Color get textSecondary => const Color(0xFF94a3b8);
  Color get background => const Color(0xFF020617);
  Color get cardSurface => const Color(0xFF1e293b);
  Color get tint => const Color(0xFFffffff);
  Color get border => const Color(0xFF334155);
  Color get icon => const Color(0xFF94a3b8);
  Color get primary => const Color(0xFF818cf8);
  Color get success => const Color(0xFF4ade80);
  Color get successBg => const Color(0xFF052e16);
  Color get error => const Color(0xFFf87171);
  Color get errorBg => const Color(0xFF450a0a);
  Color get warning => const Color(0xFFfbbf24);
  Color get warningBg => const Color(0xFF451a03);
  Color get tabIconDefault => const Color(0xFF64748b);
  Color get tabIconSelected => const Color(0xFF818cf8);
  Color get optionIndex => const Color(0xFF334155);
  Color get optionBorder => const Color(0xFF334155);
  Color get headerTitle => const Color(0xFFf8fafc);
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
