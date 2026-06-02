import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/domain/duplicate_detector.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

void main() {
  const detector = DuplicateDetector();
  final now = DateTime(2026, 6, 1);

  Subscription existing({String name = 'Spotify', String? key = 'spotify'}) =>
      Subscription(
        id: 1,
        name: name,
        serviceKey: key,
        amount: 59.99,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: now,
        category: SubscriptionCategory.music,
        createdAt: now,
        updatedAt: now,
      );

  test('same brand key → flagged with existing name', () {
    const draft = RecognizedDraft(serviceKey: 'spotify', name: 'Spotify Premium');
    expect(detector.findDuplicate(draft, [existing()]), 'Spotify');
  });

  test('same normalized name (no brand) → flagged', () {
    const draft = RecognizedDraft(name: 'spotify');
    expect(detector.findDuplicate(draft, [existing(key: null)]), 'Spotify');
  });

  test('different service → null', () {
    const draft = RecognizedDraft(serviceKey: 'netflix', name: 'Netflix');
    expect(detector.findDuplicate(draft, [existing()]), isNull);
  });

  test('empty existing list → null', () {
    const draft = RecognizedDraft(serviceKey: 'spotify', name: 'Spotify');
    expect(detector.findDuplicate(draft, const []), isNull);
  });
}
