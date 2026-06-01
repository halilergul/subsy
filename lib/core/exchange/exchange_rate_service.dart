import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';

/// Fetches current exchange rates from a public source. The only network access
/// in the app — anonymous, public data only, no personal/subscription data sent
/// (CONSTITUTION §Güvenlik). Never throws; returns a typed [Result].
abstract interface class ExchangeRateService {
  Future<Result<ExchangeRates>> fetchLatest();
}
