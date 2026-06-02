import 'package:subsy/features/subscription_import/domain/amount_parser.dart';
import 'package:subsy/features/subscription_import/domain/brand_text_matcher.dart';
import 'package:subsy/features/subscription_import/domain/date_parser.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Pure: turns recognized [OcrText] into draft subscriptions (research.md
/// D3/D6). No Flutter/plugin/network imports — exhaustively unit-tested with
/// text fixtures. Never throws; unreadable input → empty list.
///
/// Line-anchored: each catalog-brand line (or, with no brand, the first
/// amount-bearing line) starts a draft; the nearest amount/date/period in the
/// following lines fill it. This yields one draft for a single receipt and N
/// drafts for a subscriptions list (FR-008).
class SubscriptionParser {
  const SubscriptionParser({
    this.brandMatcher = const BrandTextMatcher(),
    this.amountParser = const AmountParser(),
    this.dateParser = const DateParser(),
  });

  final BrandTextMatcher brandMatcher;
  final AmountParser amountParser;
  final DateParser dateParser;

  List<RecognizedDraft> parse(OcrText text, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final accumulators = <_Acc>[];
    _Acc? current;
    String? lastTextLine;

    void flush() {
      if (current != null && current!.amount != null) accumulators.add(current!);
      current = null;
    }

    for (final line in text.lines) {
      final brands = brandMatcher.findIn(line);
      if (brands.isNotEmpty) {
        flush();
        final b = brands.first;
        current = _Acc()
          ..serviceKey = b.serviceKey
          ..name = b.displayName
          ..nameRecognized = true
          ..brandMatched = true;
      }

      final amount = amountParser.parse(line);
      if (amount != null) {
        current ??= _Acc()
          ..name = _deriveName(line, lastTextLine)
          ..nameRecognized = true;
        if (current!.amount == null) {
          current!
            ..amount = amount.amount
            ..currency = amount.currency
            ..amountRecognized = true;
        }
      }

      if (current != null) {
        final date = dateParser.parseDate(line, now: at);
        if (date != null && current!.date == null) {
          current!
            ..date = date
            ..dateRecognized = true;
        }
        final period = dateParser.parsePeriod(line);
        if (period != null && current!.period == null) {
          current!
            ..period = period
            ..periodRecognized = true;
        }
      }

      if (_hasLetters(line)) lastTextLine = line.trim();
    }
    flush();

    return accumulators.map((a) => a.toDraft(dateParser, at)).toList(growable: false);
  }

  /// Builds a plausible service name from a no-brand amount line by stripping
  /// currency/number/date/period tokens; falls back to the previous text line.
  String _deriveName(String line, String? previous) {
    var s = line
        .replaceAll(RegExp(r'[₺$€]'), ' ')
        .replaceAll(RegExp(r'\b(TRY|USD|EUR|TL)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'[\d.,:/\-]+'), ' ')
        .replaceAll(
          RegExp(r'\b(aylık|aylik|ay|yıllık|yillik|yıl|yil|haftalık|haftalik|'
              r'hafta|monthly|yearly|weekly|month|year|week|mo|yr|wk)\b',
              caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (_hasLetters(s) && s.length >= 2) return s;
    if (previous != null && _hasLetters(previous)) return previous.trim();
    return 'Abonelik';
  }

  static bool _hasLetters(String s) =>
      RegExp(r'[A-Za-zĞÜŞİÖÇğüşıöç]').hasMatch(s);
}

/// Mutable working accumulator (parser-internal).
class _Acc {
  String? serviceKey;
  String name = 'Abonelik';
  double? amount;
  Currency? currency;
  DateTime? date;
  BillingPeriod? period;
  bool nameRecognized = false;
  bool amountRecognized = false;
  bool dateRecognized = false;
  bool periodRecognized = false;
  bool brandMatched = false;

  RecognizedDraft toDraft(DateParser dateParser, DateTime now) {
    var renewal = date;
    if (renewal != null) {
      // Roll a past date forward to the next occurrence (default monthly).
      renewal = dateParser.nextOccurrence(
        renewal,
        period ?? BillingPeriod.monthly,
        now,
      );
    }
    return RecognizedDraft(
      serviceKey: serviceKey,
      name: name,
      amount: amount,
      currency: currency,
      billingPeriod: period,
      nextRenewalDate: renewal,
      confidence: RecognitionConfidence(
        nameRecognized: nameRecognized,
        amountRecognized: amountRecognized,
        dateRecognized: dateRecognized,
        periodRecognized: periodRecognized,
        brandMatched: brandMatched,
      ),
    );
  }
}
