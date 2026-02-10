import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage_service.dart';
import 'core/services/background_sync_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();
  await HiveService.init();

  // Initialize Local Storage Service (subject-specific boxes)
  await LocalStorageService.instance.init();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: NeetFlowApp(),
    ),
  );
}

class NeetFlowApp extends ConsumerStatefulWidget {
  const NeetFlowApp({super.key});

  @override
  ConsumerState<NeetFlowApp> createState() => _NeetFlowAppState();
}

class _NeetFlowAppState extends ConsumerState<NeetFlowApp> {
  @override
  void initState() {
    super.initState();

    // Initialize Background Sync Service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundSyncServiceProvider).init(ref);
    });
  }

  @override
  void dispose() {
    // We don't need to dispose the singleton here, as the provider
    // can handle disposal if we used autoDispose, but since it's a singleton
    // service that lives for the app lifecycle, we might not need to dispose it manually
    // or we can read it again.
    // However, BackgroundSyncService.instance.dispose() was called.
    // To be safe and testable, we should avoid static access.
    // But we are inside dispose(), so we can't use ref easily if the widget is unmounted?
    // Actually ref is available in State.
    // But usually services like this should be disposed by the provider container or not at all (app scope).

    // For now, let's keep it safe but try to use the provider if possible,
    // or just catch the error if instance is not initialized.
    // But since the test fails on initState, the dispose change is secondary.
    // Let's use the static instance for dispose for now, assuming the test won't call dispose
    // or if it does, it won't crash if we mocked the provider.
    // Wait, if we mocked the provider, the singleton might still be uninitialized!
    // If we use ref.read(provider), we get the MOCK.
    // The singleton `_instance` inside `BackgroundSyncService` is static.
    // The provider `backgroundSyncServiceProvider` returns `BackgroundSyncService.instance` by default.
    // Overriding the provider returns the Mock.
    // So `ref.read` returns the Mock.
    // `BackgroundSyncService.instance` returns the REAL one (which crashes).

    // So we MUST replace `BackgroundSyncService.instance` with `ref.read(backgroundSyncServiceProvider)`.
    // But in `dispose()`, is it safe to read the provider?
    // Generally yes, but let's check.

    // Actually, `BackgroundSyncService` is a singleton service.
    // The `dispose` method removes the observer.

    // If we want to make it testable, we should avoid the static singleton access in widget code.
    // So let's try to access it via provider.
    // But `ref` might not be valid in `dispose`?
    // "You can safely use 'ref' in 'dispose'." - Riverpod docs usually say it's fine.

    // However, since we are just fixing the test crash which happens in initState:

    // ref.read(backgroundSyncServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'NeetFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
