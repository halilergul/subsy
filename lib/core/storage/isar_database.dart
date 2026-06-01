import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:subsy/features/currency/data/exchange_rates_entity.dart';
import 'package:subsy/features/currency/data/target_currency_entity.dart';
import 'package:subsy/features/notifications/data/notification_settings_entity.dart';
import 'package:subsy/features/subscriptions/data/subscription_entity.dart';

/// Opens and owns the single app-wide Isar instance. All on-device data lives
/// here; nothing leaves the device (offline-first, see CONSTITUTION.md).
class IsarDatabase {
  IsarDatabase._(this.isar);

  final Isar isar;

  /// All collection schemas registered with the database.
  static const List<CollectionSchema<dynamic>> _schemas = [
    SubscriptionEntitySchema,
    NotificationSettingsEntitySchema,
    ExchangeRatesEntitySchema,
    TargetCurrencyEntitySchema,
  ];

  /// Opens the production database in the app documents directory. Reuses an
  /// already-open instance with the same name if present.
  static Future<IsarDatabase> open({String name = 'subsy'}) async {
    final existing = Isar.getInstance(name);
    if (existing != null) return IsarDatabase._(existing);

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(_schemas, directory: dir.path, name: name);
    return IsarDatabase._(isar);
  }

  /// Opens an instance at an explicit directory — used by integration tests
  /// to run against a real Isar in a temp folder.
  static Future<IsarDatabase> openAt(String directory, {String name = 'subsy'}) async {
    final existing = Isar.getInstance(name);
    if (existing != null) return IsarDatabase._(existing);
    final isar = await Isar.open(_schemas, directory: directory, name: name);
    return IsarDatabase._(isar);
  }

  Future<void> close() => isar.close();
}
