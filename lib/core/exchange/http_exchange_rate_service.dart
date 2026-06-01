import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/exchange/exchange_rate_service.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// frankfurter-backed rate fetcher. Calls `.dev/v1/latest?base=EUR&symbols=USD,TRY`
/// and parses `{amount, base, date, rates}`. The API omits the base from its
/// `rates` map, so we inject `base → 1.0` (research.md D1). Now() is injected so
/// the result is deterministic in tests.
class HttpExchangeRateService implements ExchangeRateService {
  HttpExchangeRateService(
    this._client, {
    this.base = kRateBaseCurrency,
    this.symbols = kRateSymbols,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final http.Client _client;
  final Currency base;
  final List<Currency> symbols;
  final DateTime Function() _clock;

  @override
  Future<Result<ExchangeRates>> fetchLatest() async {
    try {
      final symbolCodes = symbols.map((c) => c.code).join(',');
      final uri = Uri.parse('$kFrankfurterLatestUrl?base=${base.code}&symbols=$symbolCodes');
      final res = await _client.get(uri);
      if (res.statusCode != 200) {
        return const Failure(NetworkError(message: 'Güncel kurlar alınamadı.'));
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rawRates = body['rates'];
      if (rawRates is! Map) {
        return const Failure(NetworkError(message: 'Güncel kurlar alınamadı.'));
      }

      // Inject the base itself (omitted by the API).
      final map = <Currency, double>{base: 1.0};
      rawRates.forEach((code, value) {
        final c = Currency.fromCode(code as String);
        if (c != null && value is num) map[c] = value.toDouble();
      });

      return Success(ExchangeRates(
        base: base,
        ratesPerBase: map,
        fetchedAt: _clock(),
      ));
    } catch (e) {
      return Failure(NetworkError(cause: e));
    }
  }
}
