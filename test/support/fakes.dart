import 'dart:async';

import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/exchange/exchange_rate_service.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/currency/domain/currency_constants.dart';
import 'package:subsy/features/currency/domain/exchange_rates.dart';
import 'package:subsy/features/currency/domain/exchange_rates_repository.dart';
import 'package:subsy/features/currency/domain/target_currency_repository.dart';
import 'package:subsy/features/notifications/domain/notification_scheduler.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
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

/// Returns a canned rates result (or failure) without touching the network.
class FakeExchangeRateService implements ExchangeRateService {
  FakeExchangeRateService(this.result);
  Result<ExchangeRates> result;

  @override
  Future<Result<ExchangeRates>> fetchLatest() async => result;
}

/// In-memory rate cache for tests.
class FakeExchangeRatesRepository implements ExchangeRatesRepository {
  FakeExchangeRatesRepository([this._rates]);
  ExchangeRates? _rates;
  final _controller = StreamController<ExchangeRates?>.broadcast();

  @override
  Future<ExchangeRates?> load() async => _rates;

  @override
  Future<void> save(ExchangeRates rates) async {
    _rates = rates;
    _controller.add(rates);
  }

  @override
  Stream<ExchangeRates?> watch() async* {
    yield _rates;
    yield* _controller.stream;
  }
}

/// In-memory target-currency setting for tests.
class FakeTargetCurrencyRepository implements TargetCurrencyRepository {
  FakeTargetCurrencyRepository([Currency? initial])
      : _currency = initial ?? kDefaultTargetCurrency;
  Currency _currency;
  final _controller = StreamController<Currency>.broadcast();

  @override
  Future<Currency> load() async => _currency;

  @override
  Future<void> save(Currency currency) async {
    _currency = currency;
    _controller.add(currency);
  }

  @override
  Stream<Currency> watch() async* {
    yield _currency;
    yield* _controller.stream;
  }
}
