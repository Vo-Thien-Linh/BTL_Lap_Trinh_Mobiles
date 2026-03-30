import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/service_locator.dart' as sl;
import 'config/supabase_config.dart';
import 'app/app.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await sl.setupServiceLocator();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final hasSession = Supabase.instance.client.auth.currentSession != null;

  final initialRoute = hasSeenOnboarding
      ? (hasSession ? AppRoutes.home : AppRoutes.login)
      : AppRoutes.onboarding;

  runApp(HospitalBookingApp(initialRoute: initialRoute));
}
