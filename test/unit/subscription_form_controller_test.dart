import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscriptions/application/subscription_form_controller.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/update_subscription.dart';

import '../support/fakes.dart';

void main() {
  late FakeSubscriptionRepository repo;
  late FakePremium premium;
  final now = DateTime(2026, 6, 1);

  SubscriptionFormController controller({Subscription? editing}) {
    return SubscriptionFormController(
      add: AddSubscription(repo, premium, const BrandResolver()),
      update: UpdateSubscription(repo, const BrandResolver()),
      delete: DeleteSubscription(repo),
      now: now,
      editing: editing,
    );
  }

  Subscription seedSub({int id = 1, String name = 'Existing', double amount = 40}) {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      currency: Currency.tryl,
      billingPeriod: BillingPeriod.monthly,
      nextRenewalDate: DateTime(2026, 6, 20),
      category: SubscriptionCategory.other,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    repo = FakeSubscriptionRepository();
    premium = FakePremium(false);
  });

  group('add mode', () {
    test('valid submit saves and resolves brand', () async {
      final c = controller();
      c.setName('Netflix');
      c.setAmountText('149,99'); // comma decimal
      await c.submit();

      expect(c.state.saved, isTrue);
      expect(c.state.errorMessage, isNull);
      expect(repo.items.length, 1);
      expect(repo.items.single.serviceKey, 'netflix');
      expect(repo.items.single.amount, closeTo(149.99, 0.0001));
    });

    test('invalid input shows message and writes nothing', () async {
      final c = controller();
      c.setName('   '); // empty
      c.setAmountText('50');
      await c.submit();

      expect(c.state.saved, isFalse);
      expect(c.state.errorMessage, 'Servis adı boş olamaz.');
      expect(repo.items, isEmpty);
    });

    test('unparseable amount is rejected by the validator', () async {
      final c = controller();
      c.setName('Spotify');
      c.setAmountText('abc');
      await c.submit();
      expect(c.state.saved, isFalse);
      expect(c.state.errorMessage, 'Tutar sıfırdan büyük olmalı.');
    });

    test('free user blocked at 6th', () async {
      for (var i = 0; i < 5; i++) {
        repo.items.add(seedSub(id: i + 1, name: 'S$i'));
      }
      final c = controller();
      c.setName('Sixth');
      c.setAmountText('10');
      await c.submit();
      expect(c.state.saved, isFalse);
      expect(c.state.errorMessage, 'Ücretsiz sürüm sınırına ulaştınız.');
      expect(repo.items.length, 5);
    });
  });

  group('edit mode', () {
    test('prefills from the subscription', () {
      final c = controller(editing: seedSub(name: 'Spotify', amount: 59.99));
      expect(c.isEditing, isTrue);
      expect(c.state.name, 'Spotify');
      expect(c.state.amountText, '59.99');
      expect(c.state.editingId, 1);
    });

    test('update saves changes, keeps id, not blocked by limit', () async {
      // fill repo to the limit; editing must still work
      for (var i = 0; i < 5; i++) {
        repo.items.add(seedSub(id: i + 1, name: 'S$i'));
      }
      final c = controller(editing: repo.items.first);
      c.setAmountText('99');
      await c.submit();

      expect(c.state.saved, isTrue);
      expect(repo.items.length, 5);
      expect(repo.items.firstWhere((e) => e.id == 1).amount, 99);
    });
  });

  group('delete', () {
    test('removes the subscription and frees a slot', () async {
      repo.items.add(seedSub(id: 1));
      final c = controller(editing: repo.items.first);
      await c.delete();
      expect(c.state.saved, isTrue);
      expect(repo.items, isEmpty);
    });

    test('delete is a no-op in add mode', () async {
      final c = controller();
      await c.delete();
      expect(c.state.saved, isFalse);
    });
  });
}
