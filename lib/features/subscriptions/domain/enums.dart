/// Billing cadence for a subscription. Drives later renewal-date math.
enum BillingPeriod { weekly, monthly, yearly }

/// Supported currencies (v1). `try` is a Dart reserved word, so the Turkish
/// Lira constant is named `tryl`; use [code] for the ISO string.
enum Currency {
  tryl('TRY'),
  usd('USD'),
  eur('EUR');

  const Currency(this.code);

  /// ISO 4217 code, e.g. "TRY".
  final String code;

  /// Resolves an ISO code (case-insensitive) to a [Currency], or null.
  static Currency? fromCode(String code) {
    final upper = code.trim().toUpperCase();
    for (final c in Currency.values) {
      if (c.code == upper) return c;
    }
    return null;
  }
}

/// Classification used by the statistics feature. Defaulted from the brand
/// catalog when available, otherwise [other].
enum SubscriptionCategory {
  streaming,
  music,
  cloud,
  ai,
  productivity,
  gaming,
  education,
  health,
  books,
  security,
  connectivity,
  shopping,
  other,
}
