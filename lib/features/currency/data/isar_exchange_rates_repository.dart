import 'package:isar_community/isar.dart';
import 'package:subsy/features/currency/data/exchange_rates_entity.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/currency/domain/exchange_rates_repository.dart';

/// Isar-backed rate cache (single row, id = 0).
class IsarExchangeRatesRepository implements ExchangeRatesRepository {
  IsarExchangeRatesRepository(this._isar);

  final Isar _isar;
  static const int _id = 0;

  IsarCollection<ExchangeRatesEntity> get _col => _isar.exchangeRatesEntitys;

  @override
  Future<ExchangeRates?> load() async => (await _col.get(_id))?.toDomain();

  @override
  Future<void> save(ExchangeRates rates) async {
    await _isar.writeTxn(() => _col.put(ExchangeRatesEntity.fromDomain(rates)));
  }

  @override
  Stream<ExchangeRates?> watch() {
    return _col.watchObject(_id, fireImmediately: true).map((row) => row?.toDomain());
  }
}
