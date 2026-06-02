import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Turkish display formatting: '.' thousands, ',' decimal.
void main() {
  test('formats with Turkish grouping and decimal', () {
    expect(formatMoneyTr(229.99, Currency.tryl), '₺229,99');
    expect(formatMoneyTr(1240.5, Currency.tryl), '₺1.240,50');
    expect(formatMoneyTr(1234567.8, Currency.usd), r'$1.234.567,80');
    expect(formatMoneyTr(20, Currency.usd), r'$20,00');
    expect(formatMoneyTr(29.99, Currency.eur), '€29,99');
  });

  test('handles zero and sub-thousand without a group separator', () {
    expect(formatMoneyTr(0, Currency.tryl), '₺0,00');
    expect(formatMoneyTr(999.99, Currency.tryl), '₺999,99');
  });

  test('legacy formatMoney stays dot-decimal for machine payloads', () {
    expect(formatMoney(149.99, Currency.tryl), '₺149.99');
  });
}
