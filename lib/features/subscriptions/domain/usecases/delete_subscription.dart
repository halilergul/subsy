import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';

/// Deletes a subscription by id. Frees a free-tier slot (FR-018).
class DeleteSubscription {
  DeleteSubscription(this._repo);

  final SubscriptionRepository _repo;

  Future<Result<void>> call(int id) => _repo.delete(id);
}
