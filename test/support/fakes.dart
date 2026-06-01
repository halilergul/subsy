import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/notifications/domain/notification_scheduler.dart';
import 'package:subsy/features/notifications/domain/planned_reminder.dart';
import 'package:subsy/features/subscriptions/domain/premium_status.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';

/// In-memory subscription repository for fast, deterministic tests.
class FakeSubscriptionRepository implements SubscriptionRepository {
  final List<Subscription> items = [];
  int _nextId = 1;

  @override
  Future<Result<Subscription>> add(Subscription s) async {
    final saved = s.copyWith(id: _nextId++);
    items.add(saved);
    return Success(saved);
  }

  @override
  Future<Result<int>> count() async => Success(items.length);

  @override
  Future<Result<void>> delete(int id) async {
    items.removeWhere((e) => e.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<Subscription>>> getAll() async => Success(List.of(items));

  @override
  Future<Result<Subscription?>> getById(int id) async {
    for (final e in items) {
      if (e.id == id) return Success(e);
    }
    return const Success(null);
  }

  @override
  Future<Result<Subscription>> update(Subscription s) async {
    final i = items.indexWhere((e) => e.id == s.id);
    if (i == -1) return const Failure(NotFoundError());
    items[i] = s;
    return Success(s);
  }

  @override
  Stream<List<Subscription>> watchAll() => Stream.value(List.of(items));
}

class FakePremium implements PremiumStatus {
  FakePremium(this.isPremium);
  @override
  bool isPremium;
}

/// Records scheduling calls for notification tests; never touches the OS.
class FakeNotificationScheduler implements NotificationScheduler {
  FakeNotificationScheduler({this.permission = true});

  bool permission;
  int cancelAllCount = 0;
  List<PlannedReminder> scheduled = [];

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled = [];
  }

  @override
  Future<void> scheduleAll(List<PlannedReminder> reminders) async {
    scheduled = List.of(reminders);
  }
}
