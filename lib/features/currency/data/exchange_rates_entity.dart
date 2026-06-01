import 'package:isar_community/isar.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

part 'exchange_rates_entity.g.dart';

/// Single-row Isar cache of [ExchangeRates] (always id = 0). Currencies are
/// stored as parallel ISO-code/value lists (mapped via [Currency.fromCode]);
/// unknown codes are dropped on read so a future currency cannot corrupt the row.
@collection
class ExchangeRatesEntity {
  Id id = 0;

  late String baseCode;
  late List<String> currencyCodes;
  late List<double> rateValues;
  late DateTime fetchedAt;

  static ExchangeRatesEntity fromDomain(ExchangeRates r) {
    final codes = <String>[];
    final values = <double>[];
    r.ratesPerBase.forEach((currency, value) {
      codes.add(currency.code);
      values.add(value);
    });
    return ExchangeRatesEntity()
      ..id = 0
      ..baseCode = r.base.code
      ..currencyCodes = codes
      ..rateValues = values
      ..fetchedAt = r.fetchedAt.toUtc();
  }

  ExchangeRates toDomain() {
    final map = <Currency, double>{};
    for (var i = 0; i < currencyCodes.length && i < rateValues.length; i++) {
      final c = Currency.fromCode(currencyCodes[i]);
      if (c != null) map[c] = rateValues[i];
    }
    return ExchangeRates(
      base: Currency.fromCode(baseCode) ?? Currency.eur,
      ratesPerBase: map,
      fetchedAt: fetchedAt.toUtc(),
    );
  }
}
