import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/domain/amount_parser.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

void main() {
  const parser = AmountParser();

  test('Turkish comma decimal with ₺ symbol', () {
    final r = parser.parse('₺59,99 / ay');
    expect(r, isNotNull);
    expect(r!.amount, 59.99);
    expect(r.currency, Currency.tryl);
  });

  test('US dot decimal with \$ symbol', () {
    final r = parser.parse('Netflix \$15.99 monthly');
    expect(r!.amount, 15.99);
    expect(r.currency, Currency.usd);
  });

  test('EUR code with comma decimal', () {
    final r = parser.parse('4,99 EUR');
    expect(r!.amount, 4.99);
    expect(r.currency, Currency.eur);
  });

  test('EU grouping + comma decimal: 1.234,56 TL', () {
    final r = parser.parse('1.234,56 TL');
    expect(r!.amount, 1234.56);
    expect(r.currency, Currency.tryl);
  });

  test('US grouping + dot decimal: 1,234.56 USD', () {
    final r = parser.parse('1,234.56 USD');
    expect(r!.amount, 1234.56);
    expect(r.currency, Currency.usd);
  });

  test('single dot with 3 trailing digits is grouping: 1.234 TL', () {
    final r = parser.parse('1.234 TL');
    expect(r!.amount, 1234);
  });

  test('integer amount', () {
    final r = parser.parse('₺59');
    expect(r!.amount, 59);
  });

  test('TL token never triggers inside a word (BUTLER)', () {
    expect(parser.parse('BUTLER 15'), isNull);
  });

  test('no currency marker → null', () {
    expect(parser.parse('Sonraki ödeme 12.06.2026'), isNull);
  });

  test('no number → null', () {
    expect(parser.parse('Spotify Premium ₺'), isNull);
  });
}
