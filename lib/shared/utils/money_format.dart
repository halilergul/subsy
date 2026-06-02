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

/// Turkish-formatted money for UI display, e.g. "₺1.240,50" / "$20,00".
/// Thousands grouped with '.', decimal with ','. Locale-independent (no intl
/// locale data required). Use this in user-facing widgets; [formatMoney] stays
/// for machine-facing payloads (home widget) that expect dot decimals.
String formatMoneyTr(double amount, Currency c, {int decimals = 2}) =>
    '${currencySymbol(c)}${_groupTr(amount, decimals)}';

/// Turkish number grouping without a currency symbol, e.g. "1.240,50".
String _groupTr(double amount, int decimals) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final intPart = dot == -1 ? fixed : fixed.substring(0, dot);
  final frac = dot == -1 ? '' : fixed.substring(dot + 1);

  final grouped = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) grouped.write('.');
    grouped.write(intPart[i]);
  }

  final body = decimals > 0 ? '$grouped,$frac' : grouped.toString();
  return negative ? '-$body' : body;
}
