/// Persists whether the user has finished (or skipped) first-run onboarding.
/// On-device only — no network (CONSTITUTION: offline-first). A single flag,
/// no personal data or identifiers (spec FR-006/FR-007).
abstract interface class OnboardingRepository {
  /// Whether onboarding has been completed at least once.
  Future<bool> isCompleted();

  /// Marks onboarding as completed (idempotent).
  Future<void> markCompleted();
}
