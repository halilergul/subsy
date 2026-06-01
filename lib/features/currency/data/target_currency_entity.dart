import 'package:isar_community/isar.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

part 'target_currency_entity.g.dart';

/// Single-row Isar persistence of the target currency setting (always id = 0).
/// Stored as the ISO code; falls back to the default if unset/unknown.
@collection
class TargetCurrencyEntity {
  Id id = 0;

  late String code;

  static TargetCurrencyEntity fromDomain(Currency c) => TargetCurrencyEntity()
    ..id = 0
    ..code = c.code;

  Currency toDomain() => Currency.fromCode(code) ?? kDefaultTargetCurrency;
}
