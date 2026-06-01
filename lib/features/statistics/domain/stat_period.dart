/// Display/normalization horizon for the statistics screen. Monthly figures
/// are the dashboard's monthly-normalized amounts; yearly multiplies them by
/// [factor]. Percentages are scale-invariant, so the period never changes them.
enum StatPeriod {
  monthly(1),
  yearly(12);

  const StatPeriod(this.factor);

  /// Multiplier applied to a monthly-normalized amount (monthly→1, yearly→12).
  final int factor;
}
