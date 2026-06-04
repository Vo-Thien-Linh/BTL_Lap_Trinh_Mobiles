import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/routes/app_routes.dart';
import 'app/settings/app_settings_controller.dart';
import 'config/service_locator.dart' as sl;
import 'features/notification/data/datasources/notification_service.dart';
import 'features/notification/data/datasources/notification_template_seeder.dart';
import 'features/notification/domain/repositories/notification_repository.dart';
import 'features/onboarding/domain/usecases/has_seen_onboarding_usecase.dart';

/// Controls whether the app auto-seeds Firestore notification templates.
///
/// Default: false (do not write any sample/default templates).
/// Enable explicitly for development via:
/// `flutter run --dart-define=ENABLE_NOTIFICATION_TEMPLATE_SEEDER=true`
const bool kEnableNotificationTemplateSeeder = bool.fromEnvironment(
  'ENABLE_NOTIFICATION_TEMPLATE_SEEDER',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _safeInitializeDateFormatting();
  await _safeInitializeFirebase();

  await sl.setupServiceLocator();

  // Determine initial route based on onboarding and auth state
  String initialRoute;
  final hasSeenOnboardingUsecase = sl.getIt<HasSeenOnboardingUsecase>();
  final hasSeen = await hasSeenOnboardingUsecase();

  if (!hasSeen) {
    initialRoute = AppRoutes.onboarding;
  } else {
    // Luôn đưa vào trang đăng nhập nếu là lần 2, 3 theo yêu cầu (ngay cả khi đã login, hoặc tuỳ chọn)
    // Nếu muốn tự động vào trang chủ thì kiểm tra FirebaseAuth.instance.currentUser != null
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final effectiveUserDoc = userDoc.exists
            ? userDoc
            : await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(user.uid)
                  .get();
        if (effectiveUserDoc.exists) {
          final role =
              effectiveUserDoc.data()?['role']?.toString().toLowerCase() ??
              'patient';
          if (role == 'doctor') {
            initialRoute = AppRoutes.doctorHome;
          } else {
            initialRoute = AppRoutes.home;
          }
        } else {
          initialRoute = AppRoutes.home;
        }
      } catch (_) {
        initialRoute = AppRoutes.home;
      }
    } else {
      initialRoute = AppRoutes.login;
    }
  }

  final settingsController = AppSettingsController(
    sharedPreferences: sl.getIt(),
  );

  await settingsController.load();

  if (!sl.getIt.isRegistered<AppSettingsController>()) {
    sl.getIt.registerSingleton<AppSettingsController>(settingsController);
  }

  runApp(
    HospitalBookingApp(
      initialRoute: initialRoute,
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

    await sl.getIt<NotificationRepository>().registerCurrentDevice().timeout(
      const Duration(seconds: 10),
    );

    if (kEnableNotificationTemplateSeeder) {
      await NotificationTemplateSeeder.seedNotificationTemplates().timeout(
        const Duration(seconds: 10),
      );
    }

    debugPrint('✅ Notification system initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ Notification initialization error: $e');
    debugPrint('$stackTrace');
  }
}
