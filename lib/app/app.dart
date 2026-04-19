import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'routes/app_routes.dart';
import 'settings/app_settings_controller.dart';
import 'theme/app_theme.dart';

class HospitalBookingApp extends StatelessWidget {
  const HospitalBookingApp({
    super.key,
    required this.initialRoute,
    required this.settingsController,
  });

  final String initialRoute;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hospital Booking App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settingsController.themeMode,
          locale: Locale(settingsController.languageCode),
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: initialRoute,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
