import 'package:isar_community/isar.dart';
import 'package:subsy/features/onboarding/data/onboarding_state_entity.dart';
import 'package:subsy/features/onboarding/domain/onboarding_repository.dart';

/// Isar-backed onboarding flag (single row, id = 0).
class IsarOnboardingRepository implements OnboardingRepository {
  IsarOnboardingRepository(this._isar);

  final Isar _isar;
  static const int _id = 0;

  IsarCollection<OnboardingStateEntity> get _col => _isar.onboardingStateEntitys;

  @override
  Future<bool> isCompleted() async => (await _col.get(_id))?.completed ?? false;

  @override
  Future<void> markCompleted() async {
    await _isar.writeTxn(
      () => _col.put(OnboardingStateEntity()
        ..id = _id
        ..completed = true),
    );
  }
}
