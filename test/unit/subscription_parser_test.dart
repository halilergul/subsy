import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';
import 'package:subsy/features/subscription_import/domain/subscription_parser.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

void main() {
  const parser = SubscriptionParser();
  final now = DateTime(2026, 6, 1);

  test('single receipt → one fully-recognized draft', () {
    final drafts = parser.parse(
      const OcrText(lines: [
        'Spotify Premium',
        '₺59,99 / ay',
        'Sonraki ödeme: 12.06.2026',
      ]),
      now: now,
    );
    expect(drafts, hasLength(1));
    final d = drafts.single;
    expect(d.serviceKey, 'spotify');
    expect(d.amount, 59.99);
    expect(d.currency, Currency.tryl);
    expect(d.billingPeriod, BillingPeriod.monthly);
    expect(d.nextRenewalDate, DateTime(2026, 6, 12));
    expect(d.confidence.amountRecognized, isTrue);
    expect(d.confidence.dateRecognized, isTrue);
    expect(d.confidence.brandMatched, isTrue);
  });

  test('US-format single line draft', () {
    final drafts = parser.parse(
      const OcrText(lines: ['Netflix \$15.99 monthly next 2026-07-01']),
      now: now,
    );
    final d = drafts.single;
    expect(d.serviceKey, 'netflix');
    expect(d.amount, 15.99);
    expect(d.currency, Currency.usd);
    expect(d.billingPeriod, BillingPeriod.monthly);
    expect(d.nextRenewalDate, DateTime(2026, 7, 1));
  });

  test('App Store list → one draft per entry (FR-008)', () {
    final drafts = parser.parse(
      const OcrText(lines: [
        'Netflix',
        '₺149,99 Aylık',
        'Spotify',
        '₺59,99 Aylık',
        'YouTube Premium',
        '₺79,99 Aylık',
      ]),
      now: now,
    );
    expect(drafts.map((d) => d.serviceKey),
        ['netflix', 'spotify', 'youtube_premium']);
    expect(drafts.map((d) => d.amount), [149.99, 59.99, 79.99]);
  });

  test('multi-currency keeps each draft currency', () {
    final drafts = parser.parse(
      const OcrText(lines: [
        'Netflix',
        '\$15.99 monthly',
        'Spotify',
        '€9.99 monthly',
      ]),
      now: now,
    );
    expect(drafts.map((d) => d.currency), [Currency.usd, Currency.eur]);
  });

  test('partial: amount but no date → draft with date null, flagged', () {
    final drafts = parser.parse(
      const OcrText(lines: ['YouTube Premium ₺79,99']),
      now: now,
    );
    final d = drafts.single;
    expect(d.amount, 79.99);
    expect(d.nextRenewalDate, isNull);
    expect(d.confidence.dateRecognized, isFalse);
  });

  test('unknown brand → raw name kept, no serviceKey', () {
    final drafts = parser.parse(
      const OcrText(lines: ['Acme Cloud €4,99/ay 01.08.2026']),
      now: now,
    );
    final d = drafts.single;
    expect(d.serviceKey, isNull);
    expect(d.name, 'Acme Cloud');
    expect(d.amount, 4.99);
    expect(d.currency, Currency.eur);
    expect(d.billingPeriod, BillingPeriod.monthly);
    expect(d.nextRenewalDate, DateTime(2026, 8, 1));
    expect(d.confidence.brandMatched, isFalse);
  });

  test('garbage / no subscription → empty', () {
    final drafts = parser.parse(
      const OcrText(lines: ['random note', 'hello world']),
      now: now,
    );
    expect(drafts, isEmpty);
  });

  test('PDF-extracted invoice text → draft (parser is source-agnostic, US4)', () {
    final drafts = parser.parse(
      const OcrText(lines: [
        'FATURA / INVOICE',
        'Spotify Premium Bireysel',
        'Tutar: ₺59,99',
        'Dönem: Aylık',
        'Sonraki yenileme: 12.07.2026',
      ]),
      now: now,
    );
    final d = drafts.single;
    expect(d.serviceKey, 'spotify');
    expect(d.amount, 59.99);
    expect(d.currency, Currency.tryl);
    expect(d.billingPeriod, BillingPeriod.monthly);
    expect(d.nextRenewalDate, DateTime(2026, 7, 12));
  });

  test('past date is rolled forward to the next occurrence', () {
    final drafts = parser.parse(
      const OcrText(lines: ['Netflix ₺149,99 Aylık 12.01.2026']),
      now: now,
    );
    // 12 Jan 2026 monthly, now 1 Jun 2026 → 12 Jun 2026.
    expect(drafts.single.nextRenewalDate, DateTime(2026, 6, 12));
  });
}
