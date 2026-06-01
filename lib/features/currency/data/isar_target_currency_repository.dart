import 'package:isar_community/isar.dart';
import 'package:subsy/features/currency/data/target_currency_entity.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/target_currency_repository.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Isar-backed target-currency setting (single row, id = 0). Defaults to TRY.
class IsarTargetCurrencyRepository implements TargetCurrencyRepository {
  IsarTargetCurrencyRepository(this._isar);

  final Isar _isar;
  static const int _id = 0;

  IsarCollection<TargetCurrencyEntity> get _col => _isar.targetCurrencyEntitys;

  @override
  Future<Currency> load() async =>
      (await _col.get(_id))?.toDomain() ?? kDefaultTargetCurrency;

  @override
  Future<void> save(Currency currency) async {
    await _isar.writeTxn(() => _col.put(TargetCurrencyEntity.fromDomain(currency)));
  }

  @override
  Stream<Currency> watch() {
    return _col
        .watchObject(_id, fireImmediately: true)
        .map((row) => row?.toDomain() ?? kDefaultTargetCurrency);
  }
}
