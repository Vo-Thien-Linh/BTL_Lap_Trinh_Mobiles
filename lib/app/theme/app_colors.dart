import 'package:flutter/material.dart';

class AppColors {
  static bool _isDark = false;

  static void configure({required Brightness brightness}) {
    _isDark = brightness == Brightness.dark;
  }

  static Color get primary =>
      _isDark ? const Color(0xFF67B0FF) : const Color(0xFF2563EB);
  static Color get primaryLight =>
      _isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);
  static Color get primaryDark =>
      _isDark ? const Color(0xFF8FC7FF) : const Color(0xFF1E40AF);
  static Color get indicator =>
      _isDark ? const Color(0xFF67B0FF) : const Color(0xFF3B82F6);

  static Color get background =>
      _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get surface =>
      _isDark ? const Color(0xFF172235) : const Color(0xFFFFFFFF);
  static Color get secondary =>
      _isDark ? const Color(0xFF111B2B) : const Color(0xFFF1F5F9);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static Color get textBody =>
      _isDark ? const Color(0xFFE7ECF7) : const Color(0xFF1E293B);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFB7C5DA) : const Color(0xFF64748B);
  static Color get textHint =>
      _isDark ? const Color(0xFF8EA1BE) : const Color(0xFF94A3B8);

  static Color get border =>
      _isDark ? const Color(0xFF26344A) : const Color(0xFFE2E8F0);

  static Color get white =>
      _isDark ? const Color(0xFF172235) : const Color(0xFFFFFFFF);
  static Color get text => textBody;
  static Color get hint => textHint;
}
