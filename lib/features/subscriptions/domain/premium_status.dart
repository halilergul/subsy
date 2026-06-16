/// Whether the user has unlocked premium (no subscription cap). This feature
/// ships the free stub below; the `paywall` feature overrides the provider
/// with a RevenueCat-backed implementation (research.md D6).
abstract interface class PremiumStatus {
  bool get isPremium;
}

/// Default stub: always free tier.
class FreePremiumStatus implements PremiumStatus {
  const FreePremiumStatus();

  @override
  bool get isPremium => false;
}

/// Stub that reports premium — used by the in-app debug toggle to preview the
/// premium UI before the RevenueCat paywall ships.
class PremiumActive implements PremiumStatus {
  const PremiumActive();

  @override
  bool get isPremium => true;
}
