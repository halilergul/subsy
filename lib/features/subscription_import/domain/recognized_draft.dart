import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Per-field recognition flags so the review UI can mark what to check
/// (FR-007). Booleans (recognized vs. uncertain/missing) keep it simple and
/// fully testable.
class RecognitionConfidence {
  const RecognitionConfidence({
    this.nameRecognized = false,
    this.amountRecognized = false,
    this.dateRecognized = false,
    this.periodRecognized = false,
    this.brandMatched = false,
  });

  final bool nameRecognized;
  final bool amountRecognized;
  final bool dateRecognized;
  final bool periodRecognized;
  final bool brandMatched;

  RecognitionConfidence copyWith({
    bool? nameRecognized,
    bool? amountRecognized,
    bool? dateRecognized,
    bool? periodRecognized,
    bool? brandMatched,
  }) {
    return RecognitionConfidence(
      nameRecognized: nameRecognized ?? this.nameRecognized,
      amountRecognized: amountRecognized ?? this.amountRecognized,
      dateRecognized: dateRecognized ?? this.dateRecognized,
      periodRecognized: periodRecognized ?? this.periodRecognized,
      brandMatched: brandMatched ?? this.brandMatched,
    );
  }
}

/// A candidate subscription extracted from recognized text. Nullable fields by
/// design — recognition is best-effort; unknown fields are null and flagged for
/// the user (FR-007). Lives only in the review screen until confirmed or
/// discarded; converts to a `SubscriptionDraft` on confirm (data-model.md).
class RecognizedDraft {
  const RecognizedDraft({
    this.serviceKey,
    required this.name,
    this.amount,
    this.currency,
    this.billingPeriod,
    this.nextRenewalDate,
    this.category,
    this.confidence = const RecognitionConfidence(),
    this.duplicateOf,
  });

  /// Matched brand key from the catalog, or null when no confident match.
  final String? serviceKey;

  /// Recognized service name (raw text when no brand). Never null — falls back
  /// to the best text line; the user can edit it.
  final String name;
  final double? amount;
  final Currency? currency;
  final BillingPeriod? billingPeriod;
  final DateTime? nextRenewalDate;
  final SubscriptionCategory? category;
  final RecognitionConfidence confidence;

  /// Name of an existing subscription this likely duplicates, or null (FR-014).
  final String? duplicateOf;

  /// All required fields present → can be converted to a `SubscriptionDraft`
  /// and saved (value rules are still enforced by `SubscriptionValidator`).
  bool get isComplete =>
      name.trim().isNotEmpty &&
      amount != null &&
      currency != null &&
      nextRenewalDate != null;

  RecognizedDraft copyWith({
    String? serviceKey,
    bool clearServiceKey = false,
    String? name,
    double? amount,
    Currency? currency,
    BillingPeriod? billingPeriod,
    DateTime? nextRenewalDate,
    SubscriptionCategory? category,
    bool clearCategory = false,
    RecognitionConfidence? confidence,
    String? duplicateOf,
    bool clearDuplicate = false,
  }) {
    return RecognizedDraft(
      serviceKey: clearServiceKey ? null : (serviceKey ?? this.serviceKey),
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      category: clearCategory ? null : (category ?? this.category),
      confidence: confidence ?? this.confidence,
      duplicateOf: clearDuplicate ? null : (duplicateOf ?? this.duplicateOf),
    );
  }
}
