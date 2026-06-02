import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/onboarding/data/isar_onboarding_repository.dart';
import 'package:subsy/features/onboarding/domain/onboarding_repository.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

/// On-device onboarding-completion store (Isar). Reused by the startup gate and
/// the "show again" entry in settings.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final db = ref.watch(isarDatabaseProvider).requireValue;
  return IsarOnboardingRepository(db.isar);
});
