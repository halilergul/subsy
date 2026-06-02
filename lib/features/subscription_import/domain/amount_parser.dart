import 'package:subsy/features/subscriptions/domain/enums.dart';

/// A money value recognized from a line of text.
class ParsedAmount {
  const ParsedAmount(this.amount, this.currency);
  final double amount;
  final Currency currency;
}

/// Pure money + currency extraction from a single line (research.md D5).
/// Handles Turkish/EU (`1.234,56`) and US (`1,234.56`) groupings and the
/// markers `₺/TL/TRY/$/USD/€/EUR`. Returns null when no amount+currency is
/// present; never throws.
class AmountParser {
  const AmountParser();

  // A currency marker followed/preceded by a number, e.g. "₺59,99", "59,99 TL",
  // "$15.99", "1.234,56 EUR". Currency captured separately from the number.
  static final RegExp _number = RegExp(r'\d[\d.,]*\d|\d');

  ParsedAmount? parse(String line) {
    final currency = _detectCurrency(line);
    if (currency == null) return null;

    final match = _number.firstMatch(line);
    if (match == null) return null;

    final amount = _normalizeNumber(match.group(0)!);
    if (amount == null || !amount.isFinite || amount <= 0) return null;

    return ParsedAmount(amount, currency);
  }

  Currency? _detectCurrency(String line) {
    final upper = line.toUpperCase();
    if (line.contains('₺') || _hasToken(upper, 'TRY') || _hasToken(upper, 'TL')) {
      return Currency.tryl;
    }
    if (line.contains('€') || _hasToken(upper, 'EUR')) return Currency.eur;
    if (line.contains(r'$') || _hasToken(upper, 'USD')) return Currency.usd;
    return null;
  }

  /// Matches a 2-4 letter code as a standalone token (not inside a word), so
  /// "TL" in "NETFLIX" never triggers.
  bool _hasToken(String upper, String token) =>
      RegExp('(?<![A-Z])$token(?![A-Z])').hasMatch(upper);

  /// Normalizes a numeric token to a double, resolving grouping vs. decimal
  /// separators. Returns null if it is not a number.
  double? _normalizeNumber(String token) {
    final hasDot = token.contains('.');
    final hasComma = token.contains(',');
    String normalized;

    if (hasDot && hasComma) {
      // The right-most separator is the decimal; the other is grouping.
      final decimalSep = token.lastIndexOf(',') > token.lastIndexOf('.') ? ',' : '.';
      final groupSep = decimalSep == ',' ? '.' : ',';
      normalized = token.replaceAll(groupSep, '').replaceAll(decimalSep, '.');
    } else if (hasComma || hasDot) {
      final sep = hasComma ? ',' : '.';
      final parts = token.split(sep);
      final lastPart = parts.last;
      // Multiple occurrences, or a single one with exactly 3 trailing digits,
      // is a grouping separator (e.g. "1.234.567", "1,234") → integer.
      if (parts.length > 2 || lastPart.length == 3) {
        normalized = token.replaceAll(sep, '');
      } else {
        // Single separator with 1-2 trailing digits → decimal (e.g. "149,99").
        normalized = token.replaceAll(sep, '.');
      }
    } else {
      normalized = token;
    }

    return double.tryParse(normalized);
  }
}
