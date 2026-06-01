import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Storage contract for subscriptions. Pure CRUD — **policy-free** (no
/// validation or free-tier logic; those live in the use cases). Never throws;
/// all failures arrive as `Failure(AppError)`. Implemented by the data layer
/// (Isar today, swappable tomorrow).
abstract interface class SubscriptionRepository {
  /// Reactive list of all subscriptions; emits on every change.
  Stream<List<Subscription>> watchAll();

  /// One-shot read of all subscriptions.
  Future<Result<List<Subscription>>> getAll();

  /// Current stored count (used by the free-tier use case).
  Future<Result<int>> count();

  Future<Result<Subscription?>> getById(int id);

  /// Persists a new subscription; returns it with an assigned, stable id.
  /// Does NOT enforce the free-tier limit.
  Future<Result<Subscription>> add(Subscription subscription);

  /// Updates an existing subscription (same id); `NotFoundError` if absent.
  Future<Result<Subscription>> update(Subscription subscription);

  Future<Result<void>> delete(int id);
}
