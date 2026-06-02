import 'package:isar_community/isar.dart';

part 'onboarding_state_entity.g.dart';

/// Single-row Isar persistence of the onboarding-completion flag (always
/// id = 0). No personal data — just whether the intro was finished/skipped.
@collection
class OnboardingStateEntity {
  /// Fixed id — there is only ever one onboarding record.
  Id id = 0;

  late bool completed;
}
