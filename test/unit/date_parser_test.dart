import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/domain/date_parser.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

void main() {
  const parser = DateParser();
  final now = DateTime(2026, 6, 1);

  group('parseDate', () {
    test('Turkish day-first dd.MM.yyyy', () {
      expect(parser.parseDate('Sonraki ödeme: 12.06.2026', now: now),
          DateTime(2026, 6, 12));
    });

    test('slash dd/MM/yyyy', () {
      expect(parser.parseDate('01/08/2026', now: now), DateTime(2026, 8, 1));
    });

    test('ISO yyyy-MM-dd', () {
      expect(parser.parseDate('next 2026-07-01', now: now), DateTime(2026, 7, 1));
    });

    test('2-digit year → 2000s', () {
      expect(parser.parseDate('12.06.26', now: now), DateTime(2026, 6, 12));
    });

    test('Turkish month name with year', () {
      expect(parser.parseDate('5 Ağustos 2026', now: now), DateTime(2026, 8, 5));
    });

    test('English month name + day, year-less assumes now.year', () {
      expect(parser.parseDate('Feb 12', now: now), DateTime(2026, 2, 12));
    });

    test('invalid date rejected (31 Şubat)', () {
      expect(parser.parseDate('31.02.2026', now: now), isNull);
    });

    test('no date → null', () {
      expect(parser.parseDate('Spotify Premium ₺59,99', now: now), isNull);
    });
  });

  group('parsePeriod', () {
    test('Turkish aylık → monthly', () {
      expect(parser.parsePeriod('₺59,99 / ay'), BillingPeriod.monthly);
      expect(parser.parsePeriod('Aylık'), BillingPeriod.monthly);
    });
    test('Turkish yıllık → yearly', () {
      expect(parser.parsePeriod('149,99 / yıl'), BillingPeriod.yearly);
    });
    test('English monthly/yearly/weekly', () {
      expect(parser.parsePeriod('15.99 monthly'), BillingPeriod.monthly);
      expect(parser.parsePeriod('99 yearly'), BillingPeriod.yearly);
      expect(parser.parsePeriod('5 weekly'), BillingPeriod.weekly);
    });
    test('"May" must not be read as a period', () {
      expect(parser.parsePeriod('5 Mayıs 2026'), isNull);
    });
    test('no period → null', () {
      expect(parser.parsePeriod('Netflix'), isNull);
    });
  });

  group('nextOccurrence (roll-forward)', () {
    test('future date unchanged', () {
      expect(parser.nextOccurrence(DateTime(2026, 6, 12), BillingPeriod.monthly, now),
          DateTime(2026, 6, 12));
    });
    test('past monthly rolls forward, end-of-month clamped (drifts after Feb)', () {
      // Jan 31 → Feb 28 (clamp) → keeps 28 each step → Jun 28 (matches dashboard).
      expect(parser.nextOccurrence(DateTime(2026, 1, 31), BillingPeriod.monthly, now),
          DateTime(2026, 6, 28));
    });
    test('past yearly rolls forward to the next future anniversary', () {
      // Sep 10 2025, now Jun 1 2026 → next anniversary is Sep 10 2026.
      expect(parser.nextOccurrence(DateTime(2025, 9, 10), BillingPeriod.yearly, now),
          DateTime(2026, 9, 10));
    });
  });
}
