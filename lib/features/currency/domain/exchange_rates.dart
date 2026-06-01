import 'package:subsy/features/subscriptions/domain/enums.dart';

/// A snapshot of exchange rates relative to a [base] currency. The only
/// network-sourced data in the app; cached on-device and reused offline.
///
/// [ratesPerBase] holds units of each currency per 1 [base] and ALWAYS includes
/// `base → 1.0` (the API omits the base from its response — the client injects
/// it). Pure value type — no Flutter/http/Isar imports.
class ExchangeRates {
  const ExchangeRates({
    required this.base,
    required this.ratesPerBase,
    required this.fetchedAt,
  });

  final Currency base;
  final Map<Currency, double> ratesPerBase;

  /// When WE fetched these rates (drives the "last updated" caption).
  final DateTime fetchedAt;

  bool has(Currency c) => ratesPerBase.containsKey(c);
}
