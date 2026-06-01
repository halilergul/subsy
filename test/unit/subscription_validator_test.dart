import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/core/errors/app_error.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/subscription_validator.dart';

/// US3 (validation slice) — maps SC-005.
void main() {
  const validator = SubscriptionValidator();

  SubscriptionDraft draft({
    String name = 'Netflix',
    double amount = 149.99,
    String? notes,
  }) {
    return SubscriptionDraft(
      name: name,
      amount: amount,
      currency: Currency.tryl,
      billingPeriod: BillingPeriod.monthly,
      nextRenewalDate: DateTime.utc(2026, 6, 15),
      notes: notes,
    );
  }

  test('accepts a valid draft', () {
    expect(validator.validate(draft()), isA<Success<void>>());
  });

  test('rejects empty/whitespace name', () {
    final r = validator.validate(draft(name: '   '));
    expect(r, isA<Failure<void>>());
    expect((r as Failure<void>).error, isA<ValidationError>());
  });

  test('rejects too-long name', () {
    final r = validator.validate(draft(name: 'A' * 61));
    expect(r, isA<Failure<void>>());
  });

  test('rejects non-positive amount', () {
    expect(validator.validate(draft(amount: 0)), isA<Failure<void>>());
    expect(validator.validate(draft(amount: -5)), isA<Failure<void>>());
  });

  test('rejects non-finite amount', () {
    expect(validator.validate(draft(amount: double.infinity)), isA<Failure<void>>());
    expect(validator.validate(draft(amount: double.nan)), isA<Failure<void>>());
  });

  test('rejects too-long notes', () {
    final r = validator.validate(draft(notes: 'x' * 281));
    expect(r, isA<Failure<void>>());
  });

  test('error messages are Turkish and non-technical', () {
    final r = validator.validate(draft(name: '')) as Failure<void>;
    expect(r.error.message, 'Servis adı boş olamaz.');
  });
}
