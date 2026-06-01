import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';

/// Reactive stream of all subscriptions, for the dashboard/statistics features.
class WatchSubscriptions {
  WatchSubscriptions(this._repo);

  final SubscriptionRepository _repo;

  Stream<List<Subscription>> call() => _repo.watchAll();
}
