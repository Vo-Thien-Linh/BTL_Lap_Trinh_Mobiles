import 'package:flutter/material.dart';
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
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}