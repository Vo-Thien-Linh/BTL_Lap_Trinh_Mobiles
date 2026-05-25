import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/routes/app_routes.dart';
import 'app/settings/app_settings_controller.dart';
import 'config/service_locator.dart' as sl;
import 'features/notification/data/datasources/notification_service.dart';
import 'features/notification/data/datasources/notification_template_seeder.dart';
import 'features/notification/domain/repositories/notification_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeInitializeDateFormatting();
  await _safeInitializeFirebase();

  await sl.setupServiceLocator();

  final settingsController = AppSettingsController(
    sharedPreferences: sl.getIt(),
  );

  await settingsController.load();

  if (!sl.getIt.isRegistered<AppSettingsController>()) {
    sl.getIt.registerSingleton<AppSettingsController>(settingsController);
  }

  runApp(
    HospitalBookingApp(
      initialRoute: AppRoutes.login,
      settingsController: settingsController,
    ),
  );

  // Không await ở đây để app không bị kẹt ở màn splash Flutter.
  unawaited(_initializeNotificationSystem());
}

Future<void> _safeInitializeDateFormatting() async {
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e, stackTrace) {
    debugPrint('Date formatting initialization error: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _safeInitializeFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('$stackTrace');
  }
}

Future<void> _initializeNotificationSystem() async {
  try {
    await sl
        .getIt<NotificationService>()
        .initialize(
      onTap: (deepLink) {
        debugPrint('Notification tapped: $deepLink');
      },
      onReceived: (deepLink) {
        debugPrint('Notification received: $deepLink');
      },
    )
        .timeout(const Duration(seconds: 10));

    await sl
        .getIt<NotificationRepository>()
        .registerCurrentDevice()
        .timeout(const Duration(seconds: 10));

    await NotificationTemplateSeeder.seedNotificationTemplates()
        .timeout(const Duration(seconds: 10));

    debugPrint('✅ Notification system initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ Notification initialization error: $e');
    debugPrint('$stackTrace');
  }
}