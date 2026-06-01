import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Currency symbol for display.
String currencySymbol(Currency c) => switch (c) {
      Currency.tryl => '₺',
      Currency.usd => r'$',
      Currency.eur => '€',
    };

/// Formats an amount with its currency symbol, e.g. "₺149.99".
/// Two decimals, locale-independent (no intl locale data required).
String formatMoney(double amount, Currency c) =>
    '${currencySymbol(c)}${amount.toStringAsFixed(2)}';
