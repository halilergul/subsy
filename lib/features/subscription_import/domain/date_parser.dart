import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Pure date + billing-period extraction (research.md D5). `now` is injected
/// (no `DateTime.now()` inside) so tests are deterministic. Never throws.
class DateParser {
  const DateParser();

  // ISO: 2026-07-01
  static final RegExp _iso = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
  // Day-first: 12.06.2026 / 12/06/2026 / 12.06.26
  static final RegExp _dmy = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})');
  // Textual day + month name + optional year: "12 Şubat 2026", "5 Ağustos"
  static final RegExp _textDmy =
      RegExp(r'(\d{1,2})\s+([A-Za-zĞÜŞİÖÇğüşıöç]+)\.?\s*(\d{4})?');
  // Textual month name + day: "Feb 12", "Şubat 12"
  static final RegExp _textMd = RegExp(r'([A-Za-zĞÜŞİÖÇğüşıöç]+)\.?\s+(\d{1,2})\b');

  /// Turkish + English month names → 1..12. Folded to ASCII-lower at lookup.
  static const Map<String, int> _months = {
    'ocak': 1, 'subat': 2, 'mart': 3, 'nisan': 4, 'mayis': 5, 'haziran': 6,
    'temmuz': 7, 'agustos': 8, 'eylul': 9, 'ekim': 10, 'kasim': 11, 'aralik': 12,
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
    'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11,
    'december': 12,
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'sept': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    'oca': 1, 'sub': 2, 'nis': 4, 'haz': 6, 'tem': 7, 'agu': 8, 'eyl': 9,
    'eki': 10, 'kas': 11, 'ara': 12,
  };

  /// Returns the first parseable date in [text], or null. Year-less textual
  /// dates assume [now]'s year. Does NOT roll forward — use [nextOccurrence].
  DateTime? parseDate(String text, {required DateTime now}) {
    final iso = _iso.firstMatch(text);
    if (iso != null) {
      return _build(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
    }

    final dmy = _dmy.firstMatch(text);
    if (dmy != null) {
      final year = _normalizeYear(int.parse(dmy[3]!));
      return _build(year, int.parse(dmy[2]!), int.parse(dmy[1]!));
    }

    final textDmy = _textDmy.firstMatch(text);
    if (textDmy != null) {
      final month = _monthOf(textDmy[2]!);
      if (month != null) {
        final year = textDmy[3] != null ? int.parse(textDmy[3]!) : now.year;
        return _build(year, month, int.parse(textDmy[1]!));
      }
    }

    final textMd = _textMd.firstMatch(text);
    if (textMd != null) {
      final month = _monthOf(textMd[1]!);
      if (month != null) {
        return _build(now.year, month, int.parse(textMd[2]!));
      }
    }
    return null;
  }

  /// Detects a billing period from period keywords, or null when absent.
  BillingPeriod? parsePeriod(String text) {
    final n = _fold(text);
    if (RegExp(r'yil|yıl|year|annual|/\s*yr|\byr\b').hasMatch(n)) {
      return BillingPeriod.yearly;
    }
    if (RegExp(r'hafta|week|/\s*wk|\bwk\b').hasMatch(n)) {
      return BillingPeriod.weekly;
    }
    if (RegExp(r'\bay\b|aylik|month|/\s*mo\b|\bmo\b').hasMatch(n)) {
      return BillingPeriod.monthly;
    }
    return null;
  }

  /// Rolls [date] forward by [period] until it is today or later (calendar-aware,
  /// end-of-month clamped) — the same effective-renewal rule as the dashboard.
  DateTime nextOccurrence(DateTime date, BillingPeriod period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(date.year, date.month, date.day);
    if (!next.isBefore(today)) return next;
    switch (period) {
      case BillingPeriod.weekly:
        while (next.isBefore(today)) {
          next = next.add(const Duration(days: 7));
        }
      case BillingPeriod.monthly:
        while (next.isBefore(today)) {
          next = _addMonthsClamped(next, 1);
        }
      case BillingPeriod.yearly:
        while (next.isBefore(today)) {
          next = _addMonthsClamped(next, 12);
        }
    }
    return next;
  }

  int? _monthOf(String word) => _months[_fold(word)];

  /// 2-digit year → 2000s; 4-digit passes through.
  int _normalizeYear(int y) => y < 100 ? 2000 + y : y;

  /// Builds a valid date, or null when the day/month is out of range.
  DateTime? _build(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    // Reject overflow (e.g. 31 Feb → Mar 3).
    if (date.month != month || date.day != day) return null;
    return date;
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final total = date.month - 1 + months;
    final year = date.year + total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day <= lastDay ? date.day : lastDay;
    return DateTime(year, month, day);
  }

  /// Folds Turkish characters to ASCII + lowercases (mirrors BrandResolver).
  static String _fold(String input) {
    const folds = {
      'İ': 'i', 'I': 'i', 'ı': 'i',
      'Ş': 's', 'ş': 's', 'Ğ': 'g', 'ğ': 'g',
      'Ç': 'c', 'ç': 'c', 'Ö': 'o', 'ö': 'o', 'Ü': 'u', 'ü': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(folds[ch] ?? ch);
    }
    return buffer.toString().toLowerCase();
  }
}
