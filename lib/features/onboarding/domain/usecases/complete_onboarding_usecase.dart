import '../repositories/onboarding_repository.dart';

class CompleteOnboardingUsecase {
  final OnboardingRepository repository;

  CompleteOnboardingUsecase({required this.repository});

  Future<void> call() async {
    await repository.completeOnboarding();
  }
}
