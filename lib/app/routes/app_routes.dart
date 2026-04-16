import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/register_success_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/doctor/presentation/pages/doctor_home_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/appointment/presentation/pages/booking_flow_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../data/models/user_model.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerSuccess = '/register-success';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';
  static const String doctorHome = '/doctor-home';
  static const String booking = '/booking';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return _buildRoute(const OnboardingScreen());
      case login:
        return _buildRoute(const LoginPage());
      case register:
        return _buildRoute(const RegisterPage());
      case registerSuccess:
        final email = settings.arguments as String?;
        return _buildRoute(RegisterSuccessPage(email: email));
      case forgotPassword:
        return _buildRoute(const ForgotPasswordPage());
      case verifyEmail:
        return _buildRoute(const VerifyEmailPage());
      case home:
        return _buildRoute(const HomePage());
      case doctorHome:
        return _buildRoute(const DoctorHomePage());
      case booking:
        return _buildRoute(const BookingFlowPage());
      case profile:
        return _buildRoute(const ProfilePage());
      case editProfile:
        final user = settings.arguments as UserModel;
        return _buildRoute(EditProfilePage(user: user));
      default:
        return _buildRoute(const LoginPage());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

        final slide =
            Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
