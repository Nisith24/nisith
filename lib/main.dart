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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  runApp(const ProviderScope(child: NeetFlowApp()));
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
      BackgroundSyncService.instance.init(ref);
    });
  }

  @override
  void dispose() {
    BackgroundSyncService.instance.dispose();
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
