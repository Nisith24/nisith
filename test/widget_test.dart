// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neetflow_flutter/main.dart';
import 'package:neetflow_flutter/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme smoke test', (WidgetTester tester) async {
    // Instead of pumping the full NeetFlowApp which requires Firebase initialization,
    // we will pump a simple MaterialApp using our AppTheme to ensure the theme config is valid.

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: Text('Theme Test')),
        ),
      ),
    );

    // Verify that the app builds without crashing.
    expect(find.text('Theme Test'), findsOneWidget);

    // Verify theme properties are applied
    final context = tester.element(find.text('Theme Test'));
    final theme = Theme.of(context);
    expect(theme.useMaterial3, true);
  });
}
