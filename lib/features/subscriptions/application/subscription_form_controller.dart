import 'package:flutter/foundation.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/delete_subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/update_subscription.dart';

enum SubscriptionFormMode { add, edit }

/// Immutable UI state for the subscription form. Field values are UI-friendly
/// (amount as text) and converted to a [SubscriptionDraft] on submit.
@immutable
class SubscriptionFormState {
  const SubscriptionFormState({
    required this.mode,
    this.editingId,
    required this.name,
    required this.amountText,
    required this.currency,
    required this.billingPeriod,
    required this.nextRenewalDate,
    this.category,
    this.startDate,
    this.notes,
    this.isSubmitting = false,
    this.errorMessage,
    this.saved = false,
  });

  final SubscriptionFormMode mode;
  final int? editingId;
  final String name;
  final String amountText;
  final Currency currency;
  final BillingPeriod billingPeriod;
  final DateTime nextRenewalDate;
  final SubscriptionCategory? category;
  final DateTime? startDate;
  final String? notes;
  final bool isSubmitting;
  final String? errorMessage;
  final bool saved;

  factory SubscriptionFormState.initial(DateTime now) => SubscriptionFormState(
        mode: SubscriptionFormMode.add,
        name: '',
        amountText: '',
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: DateTime(now.year, now.month, now.day),
      );

  factory SubscriptionFormState.fromSubscription(Subscription s) => SubscriptionFormState(
        mode: SubscriptionFormMode.edit,
        editingId: s.id,
        name: s.name,
        amountText: _formatAmount(s.amount),
        currency: s.currency,
        billingPeriod: s.billingPeriod,
        nextRenewalDate: s.nextRenewalDate,
        category: s.category,
        startDate: s.startDate,
        notes: s.notes,
      );

  SubscriptionFormState copyWith({
    String? name,
    String? amountText,
    Currency? currency,
    BillingPeriod? billingPeriod,
    DateTime? nextRenewalDate,
    SubscriptionCategory? category,
    bool clearCategory = false,
    DateTime? startDate,
    bool clearStartDate = false,
    String? notes,
    bool clearNotes = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? saved,
  }) {
    return SubscriptionFormState(
      mode: mode,
      editingId: editingId,
      name: name ?? this.name,
      amountText: amountText ?? this.amountText,
      currency: currency ?? this.currency,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      category: clearCategory ? null : (category ?? this.category),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      notes: clearNotes ? null : (notes ?? this.notes),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saved: saved ?? this.saved,
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
    return amount.toString();
  }
}

/// Holds the form state and orchestrates submit/delete via the core use cases.
/// Plain [ChangeNotifier] so it is trivially unit-testable (inject fakes); the
/// screen builds it from Riverpod use-case providers. All business rules
/// (validation, brand enrichment, free-tier limit) live in the use cases.
class SubscriptionFormController extends ChangeNotifier {
  SubscriptionFormController({
    required AddSubscription add,
    required UpdateSubscription update,
    required DeleteSubscription delete,
    required DateTime now,
    Subscription? editing,
  })  : _add = add,
        _update = update,
        _delete = delete {
    _state = editing == null
        ? SubscriptionFormState.initial(now)
        : SubscriptionFormState.fromSubscription(editing);
  }

  final AddSubscription _add;
  final UpdateSubscription _update;
  final DeleteSubscription _delete;

  late SubscriptionFormState _state;
  SubscriptionFormState get state => _state;

  bool get isEditing => _state.mode == SubscriptionFormMode.edit;

  void _set(SubscriptionFormState next) {
    _state = next;
    notifyListeners();
  }

  void setName(String v) => _set(_state.copyWith(name: v, clearError: true));
  void setAmountText(String v) => _set(_state.copyWith(amountText: v, clearError: true));
  void setCurrency(Currency v) => _set(_state.copyWith(currency: v));
  void setBillingPeriod(BillingPeriod v) => _set(_state.copyWith(billingPeriod: v));
  void setNextRenewalDate(DateTime v) => _set(_state.copyWith(nextRenewalDate: v));
  void setCategory(SubscriptionCategory? v) =>
      _set(_state.copyWith(category: v, clearCategory: v == null));
  void setStartDate(DateTime? v) =>
      _set(_state.copyWith(startDate: v, clearStartDate: v == null));
  void setNotes(String? v) =>
      _set(_state.copyWith(notes: v, clearNotes: v == null || v.isEmpty));

  SubscriptionDraft _buildDraft() {
    return SubscriptionDraft(
      name: _state.name,
      amount: _parseAmount(_state.amountText),
      currency: _state.currency,
      billingPeriod: _state.billingPeriod,
      nextRenewalDate: _state.nextRenewalDate,
      category: _state.category,
      startDate: _state.startDate,
      notes: _state.notes,
    );
  }

  Future<void> submit() async {
    _set(_state.copyWith(isSubmitting: true, clearError: true));
    final draft = _buildDraft();
    final result = isEditing
        ? await _update(_state.editingId!, draft)
        : await _add(draft);
    switch (result) {
      case Success<Subscription>():
        _set(_state.copyWith(isSubmitting: false, saved: true));
      case Failure<Subscription>(:final error):
        _set(_state.copyWith(isSubmitting: false, errorMessage: error.message));
    }
  }

  Future<void> delete() async {
    if (!isEditing) return;
    _set(_state.copyWith(isSubmitting: true, clearError: true));
    final result = await _delete(_state.editingId!);
    switch (result) {
      case Success<void>():
        _set(_state.copyWith(isSubmitting: false, saved: true));
      case Failure<void>(:final error):
        _set(_state.copyWith(isSubmitting: false, errorMessage: error.message));
    }
  }

  /// Parses "149,99" / "149.99" → 149.99; unparseable → NaN so the core
  /// validator rejects it with the proper Turkish message.
  static double _parseAmount(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? double.nan;
  }
}
