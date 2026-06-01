import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Persists the user's chosen target currency for unified totals (single row).
/// Defaults to TRY when unset (FR-008/009).
abstract interface class TargetCurrencyRepository {
  Future<Currency> load();
  Future<void> save(Currency currency);
  Stream<Currency> watch();
}
