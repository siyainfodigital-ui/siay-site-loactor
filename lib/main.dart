import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/routes/app_routes.dart';
import 'app/services/cache_service.dart';
import 'app/services/offline_sync_service.dart';
import 'app/theme/app_theme.dart';
import 'app/bindings/auth_binding.dart';

import 'dart:ui';
import 'app/services/log_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logService = Get.put(LogService());

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logService.addError(details.exception, details.stack ?? StackTrace.empty);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logService.addError(error, stack);
    return true;
  };

  // Load .env
  await dotenv.load(fileName: '.env');

  // Initialise Supabase (free plan)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialise Hive offline cache
  await CacheService.init();

  // Initialize Offline Sync Service
  Get.put(OfflineSyncService());

  // Lock to portrait for mobile field workers
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Solar-themed status bar (transparent, light icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SiyaSiteLocatorApp());
}

class SiyaSiteLocatorApp extends StatelessWidget {
  const SiyaSiteLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Siya Site Locator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: AuthBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),

      // Marathi primary locale; falls back to English
      locale: const Locale('mr', 'IN'),
      fallbackLocale: const Locale('en', 'US'),

      // Fix text scale for rural devices
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.0),
        ),
        child: child!,
      ),
    );
  }
}
