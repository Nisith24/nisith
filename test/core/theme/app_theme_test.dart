import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neetflow_flutter/core/theme/app_colors.dart';
import 'package:neetflow_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('Light theme properties', () {
      final theme = AppTheme.light;
      const colors = AppColors.light;

      // Check brightness
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);

      // Check scaffold background
      expect(theme.scaffoldBackgroundColor, colors.background);

      // Check color scheme
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.secondary, colors.primary);
      expect(theme.colorScheme.surface, colors.cardSurface);
      expect(theme.colorScheme.error, colors.error);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.onSecondary, Colors.white);
      expect(theme.colorScheme.onSurface, colors.text);
      expect(theme.colorScheme.onError, Colors.white);

      // Check AppBar theme
      expect(theme.appBarTheme.backgroundColor, colors.background);
      expect(theme.appBarTheme.foregroundColor, colors.text);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);

      // Check Card theme
      expect(theme.cardTheme.color, colors.cardSurface);
      expect(theme.cardTheme.elevation, 2);
      // expect(theme.cardTheme.shadowColor, Colors.black.withValues(alpha: 0.08));
      // Note: testing shadow color opacity might be tricky due to floating point.
      expect(theme.cardTheme.shadowColor?.toARGB32(), Colors.black.withValues(alpha: 0.08).toARGB32());
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, colors.border);

      // Check InputDecoration theme
      expect(theme.inputDecorationTheme.filled, true);
      expect(theme.inputDecorationTheme.fillColor, colors.cardSurface);
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      expect(theme.inputDecorationTheme.enabledBorder, isA<OutlineInputBorder>());
      expect(theme.inputDecorationTheme.focusedBorder, isA<OutlineInputBorder>());

      // Check ElevatedButton theme
      final elevatedButtonStyle = theme.elevatedButtonTheme.style;
      expect(elevatedButtonStyle?.backgroundColor?.resolve({}), colors.primary);
      expect(elevatedButtonStyle?.foregroundColor?.resolve({}), Colors.white);

      // Check TextButton theme
      final textButtonStyle = theme.textButtonTheme.style;
      expect(textButtonStyle?.foregroundColor?.resolve({}), colors.primary);

      // Check TextTheme
      expect(theme.textTheme.headlineLarge?.color, colors.headerTitle);
      expect(theme.textTheme.headlineLarge?.fontSize, 32);
      expect(theme.textTheme.bodyLarge?.color, colors.text);
      expect(theme.textTheme.bodySmall?.color, colors.textSecondary);
    });

    test('Dark theme properties', () {
      final theme = AppTheme.dark;
      const colors = AppColors.dark;

      // Check brightness
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);

      // Check scaffold background
      expect(theme.scaffoldBackgroundColor, colors.background);

      // Check color scheme
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.secondary, colors.primary);
      expect(theme.colorScheme.surface, colors.cardSurface);
      expect(theme.colorScheme.error, colors.error);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.onSecondary, Colors.white);
      expect(theme.colorScheme.onSurface, colors.text);
      expect(theme.colorScheme.onError, Colors.white);

      // Check Card theme
      expect(theme.cardTheme.shadowColor?.toARGB32(), Colors.black.withValues(alpha: 0.15).toARGB32());
    });
  });
}
