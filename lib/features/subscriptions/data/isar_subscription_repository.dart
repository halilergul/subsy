import 'package:isar_community/isar.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/data/subscription_entity.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';

/// Isar-backed [SubscriptionRepository]. Pure CRUD; maps any Isar/IO failure
/// to a typed [StorageError] so callers never see a raw exception (FR-009).
class IsarSubscriptionRepository implements SubscriptionRepository {
  IsarSubscriptionRepository(this._isar);

  final Isar _isar;

  IsarCollection<SubscriptionEntity> get _col => _isar.subscriptionEntitys;

  @override
  Stream<List<Subscription>> watchAll() {
    // fireImmediately so a new listener gets the current list right away.
    return _col
        .where()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  @override
  Future<Result<List<Subscription>>> getAll() async {
    try {
      final rows = await _col.where().findAll();
      return Success(rows.map((e) => e.toDomain()).toList());
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }

  @override
  Future<Result<int>> count() async {
    try {
      return Success(await _col.count());
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }

  @override
  Future<Result<Subscription?>> getById(int id) async {
    try {
      final row = await _col.get(id);
      return Success(row?.toDomain());
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }

  @override
  Future<Result<Subscription>> add(Subscription subscription) async {
    try {
      final entity = SubscriptionEntity.fromDomain(subscription);
      final id = await _isar.writeTxn(() => _col.put(entity));
      final saved = subscription.copyWith(id: id);
      return Success(saved);
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }

  @override
  Future<Result<Subscription>> update(Subscription subscription) async {
    final id = subscription.id;
    if (id == null) {
      return const Failure(NotFoundError());
    }
    try {
      final existing = await _col.get(id);
      if (existing == null) {
        return const Failure(NotFoundError());
      }
      final entity = SubscriptionEntity.fromDomain(subscription);
      await _isar.writeTxn(() => _col.put(entity));
      return Success(subscription);
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _isar.writeTxn(() => _col.delete(id));
      return const Success(null);
    } catch (e) {
      return Failure(StorageError(cause: e));
    }
  }
}
