import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Đóng dòng báo trạng thái cũ để lúc nào chạy cũng vào Onboarding (tiện Test UI)
  // final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final hasSeenOnboarding = false;

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)), // Elegant deep Teal
        useMaterial3: true,
      ),
      home: hasSeenOnboarding ? const Scaffold(body: Center(child: Text('Màn hình chính'))) : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
