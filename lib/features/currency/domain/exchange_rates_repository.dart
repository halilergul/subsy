import 'package:subsy/features/currency/domain/exchange_rates.dart';

/// On-device cache of the last-fetched exchange rates (single row). Keeps the
/// app working offline (cache-first). Null when no rates have ever been fetched.
abstract interface class ExchangeRatesRepository {
  Future<ExchangeRates?> load();
  Future<void> save(ExchangeRates rates);
  Stream<ExchangeRates?> watch();
}
