import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/premium_status.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/subscription_repository.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';

/// In-memory fake repository for fast, deterministic use-case tests.
class FakeSubscriptionRepository implements SubscriptionRepository {
  final List<Subscription> _items = [];
  int _nextId = 1;

  @override
  Future<Result<Subscription>> add(Subscription s) async {
    final saved = s.copyWith(id: _nextId++);
    _items.add(saved);
    return Success(saved);
  }

  @override
  Future<Result<int>> count() async => Success(_items.length);

  @override
  Future<Result<void>> delete(int id) async {
    _items.removeWhere((e) => e.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<Subscription>>> getAll() async => Success(List.of(_items));

  @override
  Future<Result<Subscription?>> getById(int id) async {
    for (final e in _items) {
      if (e.id == id) return Success(e);
    }
    return const Success(null);
  }

  @override
  Future<Result<Subscription>> update(Subscription s) async {
    final i = _items.indexWhere((e) => e.id == s.id);
    if (i == -1) return const Failure(NotFoundError());
    _items[i] = s;
    return Success(s);
  }

  @override
  Stream<List<Subscription>> watchAll() => Stream.value(List.of(_items));
}

class FakePremium implements PremiumStatus {
  FakePremium(this.isPremium);
  @override
  bool isPremium;
}

void main() {
  late FakeSubscriptionRepository repo;
  late FakePremium premium;

  SubscriptionDraft draft([String name = 'Service']) => SubscriptionDraft(
        name: name,
        amount: 50,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: DateTime.utc(2026, 6, 15),
      );

  AddSubscription buildAdd() =>
      AddSubscription(repo, premium, const BrandResolver());

  setUp(() {
    repo = FakeSubscriptionRepository();
    premium = FakePremium(false);
  });

  test('free user can add up to 5 subscriptions', () async {
    final add = buildAdd();
    for (var i = 0; i < 5; i++) {
      expect(await add(draft('S$i')), isA<Success<Subscription>>());
    }
    expect((await repo.count() as Success<int>).value, 5);
  });

  test('free user is blocked at the 6th; store unchanged', () async {
    final add = buildAdd();
    for (var i = 0; i < 5; i++) {
      await add(draft('S$i'));
    }
    final sixth = await add(draft('S6'));
    expect(sixth, isA<Failure<Subscription>>());
    expect((sixth as Failure<Subscription>).error, isA<LimitReachedError>());
    expect((await repo.count() as Success<int>).value, 5);
  });

  test('deleting frees a slot so a new add succeeds', () async {
    final add = buildAdd();
    final ids = <int>[];
    for (var i = 0; i < 5; i++) {
      final r = await add(draft('S$i')) as Success<Subscription>;
      ids.add(r.value.id!);
    }
    await repo.delete(ids.first);
    expect(await add(draft('New')), isA<Success<Subscription>>());
  });

  test('premium user is never blocked', () async {
    premium.isPremium = true;
    final add = buildAdd();
    for (var i = 0; i < 8; i++) {
      expect(await add(draft('S$i')), isA<Success<Subscription>>());
    }
    expect((await repo.count() as Success<int>).value, 8);
  });

  test('invalid draft is rejected before any write', () async {
    final add = buildAdd();
    final r = await add(draft('')); // empty name
    expect(r, isA<Failure<Subscription>>());
    expect((r as Failure<Subscription>).error, isA<ValidationError>());
    expect((await repo.count() as Success<int>).value, 0);
  });

  test('brand is auto-resolved on add (serviceKey + default category)', () async {
    final add = buildAdd();
    final r = await add(draft('Netflix')) as Success<Subscription>;
    expect(r.value.serviceKey, 'netflix');
    expect(r.value.category, SubscriptionCategory.streaming);
  });

  test('unknown service leaves serviceKey null, category other', () async {
    final add = buildAdd();
    final r = await add(draft('Mystery Service')) as Success<Subscription>;
    expect(r.value.serviceKey, isNull);
    expect(r.value.category, SubscriptionCategory.other);
  });
}
