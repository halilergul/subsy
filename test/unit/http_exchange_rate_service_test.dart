import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subsy/core/exchange/http_exchange_rate_service.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Service parse contract (SC-008: only a public rate request; base injected).
void main() {
  final fixedNow = DateTime(2026, 6, 1, 12);

  HttpExchangeRateService service(MockClient client) =>
      HttpExchangeRateService(client, clock: () => fixedNow);

  test('parses frankfurter JSON and injects base → 1.0', () async {
    final client = MockClient((req) async {
      expect(req.url.host, 'api.frankfurter.dev');
      return http.Response(
        '{"amount":1.0,"base":"EUR","date":"2026-06-01","rates":{"USD":1.10,"TRY":45.0}}',
        200,
      );
    });

    final res = await service(client).fetchLatest();
    final rates = (res as Success).value;
    expect(rates.base, Currency.eur);
    expect(rates.ratesPerBase[Currency.eur], 1.0); // injected base
    expect(rates.ratesPerBase[Currency.usd], 1.10);
    expect(rates.ratesPerBase[Currency.tryl], 45.0);
    expect(rates.fetchedAt, fixedNow);
  });

  test('non-200 → Failure(NetworkError)', () async {
    final client = MockClient((req) async => http.Response('nope', 503));
    expect(await service(client).fetchLatest(), isA<Failure>());
  });

  test('garbage body → Failure(NetworkError)', () async {
    final client = MockClient((req) async => http.Response('not json', 200));
    expect(await service(client).fetchLatest(), isA<Failure>());
  });
}
