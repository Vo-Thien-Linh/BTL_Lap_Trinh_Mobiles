import '../repositories/onboarding_repository.dart';

class HasSeenOnboardingUsecase {
  final OnboardingRepository repository;

  HasSeenOnboardingUsecase({required this.repository});

  Future<bool> call() async {
    return repository.hasSeenOnboarding();
  }
}
