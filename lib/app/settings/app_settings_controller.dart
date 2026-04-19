import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  final SharedPreferences _sharedPreferences;

  static const String _themeModeKey = 'settings.theme_mode';
  static const String _languageKey = 'settings.language';
  static const String _notificationsEnabledKey =
      'settings.notifications_enabled';
  static const String _appointmentRemindersKey =
      'settings.notifications_appointment_reminders';
  static const String _promotionsKey = 'settings.notifications_promotions';

  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'vi';
  bool _notificationsEnabled = true;
  bool _appointmentReminders = true;
  bool _promotionsEnabled = false;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get appointmentReminders => _appointmentReminders;
  bool get promotionsEnabled => _promotionsEnabled;

  Future<void> load() async {
    final themeName = _sharedPreferences.getString(_themeModeKey);
    _themeMode = _parseThemeMode(themeName);
    _languageCode = _sharedPreferences.getString(_languageKey) ?? 'vi';
    _notificationsEnabled =
        _sharedPreferences.getBool(_notificationsEnabledKey) ?? true;
    _appointmentReminders =
        _sharedPreferences.getBool(_appointmentRemindersKey) ?? true;
    _promotionsEnabled = _sharedPreferences.getBool(_promotionsKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _sharedPreferences.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLanguageCode(String value) async {
    if (_languageCode == value) return;
    _languageCode = value;
    await _sharedPreferences.setString(_languageKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _sharedPreferences.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }

  Future<void> setAppointmentReminders(bool value) async {
    _appointmentReminders = value;
    await _sharedPreferences.setBool(_appointmentRemindersKey, value);
    notifyListeners();
  }

  Future<void> setPromotionsEnabled(bool value) async {
    _promotionsEnabled = value;
    await _sharedPreferences.setBool(_promotionsKey, value);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
