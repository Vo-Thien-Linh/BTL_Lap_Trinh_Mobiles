import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingLocalDatasource {
  Future<bool> hasSeenOnboarding();
  Future<void> completeOnboarding();
}

class OnboardingLocalDatasourceImpl implements OnboardingLocalDatasource {
  final SharedPreferences sharedPreferences;

  OnboardingLocalDatasourceImpl({required this.sharedPreferences});

  @override
  Future<bool> hasSeenOnboarding() async {
    return sharedPreferences.getBool('has_seen_onboarding') ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    await sharedPreferences.setBool('has_seen_onboarding', true);
  }
}
