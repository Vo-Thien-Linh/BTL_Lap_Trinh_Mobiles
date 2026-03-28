import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import '../onboarding_screen.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class HospitalBookingApp extends StatelessWidget {
  const HospitalBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Booking App',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      routes: {'/onboarding': (_) => const OnboardingScreen()},
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
