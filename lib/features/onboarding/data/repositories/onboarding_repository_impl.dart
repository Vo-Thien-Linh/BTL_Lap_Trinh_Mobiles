import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDatasource localDatasource;

  OnboardingRepositoryImpl({required this.localDatasource});

  @override
  Future<bool> hasSeenOnboarding() async {
    return localDatasource.hasSeenOnboarding();
  }

  @override
  Future<void> completeOnboarding() async {
    await localDatasource.completeOnboarding();
  }
}
