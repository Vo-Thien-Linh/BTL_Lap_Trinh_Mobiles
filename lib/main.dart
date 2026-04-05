import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/service_locator.dart' as sl;
import 'app/app.dart';
import 'app/routes/app_routes.dart';
import 'features/onboarding/domain/usecases/has_seen_onboarding_usecase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp();

  await sl.setupServiceLocator();

  final hasSeenOnboarding = await sl.getIt<HasSeenOnboardingUsecase>()();
  final hasSession = FirebaseAuth.instance.currentUser != null;

  final initialRoute = hasSeenOnboarding
      ? (hasSession ? AppRoutes.home : AppRoutes.login)
      : AppRoutes.onboarding;

  runApp(HospitalBookingApp(initialRoute: initialRoute));
}
