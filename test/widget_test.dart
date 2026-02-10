import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neetflow_flutter/core/services/background_sync_service.dart';
import 'package:neetflow_flutter/features/auth/providers/auth_provider.dart';
import 'package:neetflow_flutter/core/models/user_profile.dart';
import 'package:neetflow_flutter/main.dart';
import 'package:neetflow_flutter/core/theme/theme_provider.dart';

// Create a mock for BackgroundSyncService
class MockBackgroundSyncService extends Fake implements BackgroundSyncService {
  @override
  void init(WidgetRef ref) {
    // No-op for tests
  }

  @override
  void dispose() {
    // No-op for tests
  }
}

// Create a mock for AuthNotifier
class MockAuthNotifier extends StateNotifier<AsyncValue<AuthState>> implements AuthNotifier {
  MockAuthNotifier() : super(const AsyncValue.data(AuthState(isLoading: false)));

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password, String name) async {}

  @override
  Future<void> signOut() async {}

  @override
  void markMcqViewed(String mcqId) {}

  @override
  void updateUserProfileLocally(UserProfile Function(UserProfile?) updater) {}
}

// Mock ThemeNotifier to avoid Hive access
class MockThemeNotifier extends StateNotifier<ThemeMode> implements ThemeNotifier {
  MockThemeNotifier() : super(ThemeMode.light);

  @override
  void toggleTheme() {}

  // We don't need _loadTheme because we set initial state in super
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backgroundSyncServiceProvider.overrideWithValue(MockBackgroundSyncService()),
          authStateProvider.overrideWith((ref) => MockAuthNotifier()),
          themeProvider.overrideWith((ref) => MockThemeNotifier()),
        ],
        child: const NeetFlowApp(),
      ),
    );

    // Verify that our app starts.
    expect(find.byType(NeetFlowApp), findsOneWidget);
  });
}
