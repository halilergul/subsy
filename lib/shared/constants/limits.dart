import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Maximum number of subscriptions a non-premium user may store (FR-015).
const int kFreeSubscriptionLimit = 5;

/// Currencies accepted by the app in v1 (FR-008).
const Set<Currency> kSupportedCurrencies = {
  Currency.tryl,
  Currency.usd,
  Currency.eur,
};

/// Validation bounds (data-model.md).
const int kMaxNameLength = 60;
const int kMaxNotesLength = 280;
