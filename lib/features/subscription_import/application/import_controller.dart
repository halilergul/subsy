import 'package:flutter/foundation.dart';
import 'package:subsy/core/result/result.dart';
import 'package:subsy/features/subscription_import/domain/duplicate_detector.dart';
import 'package:subsy/features/subscription_import/domain/image_picker_port.dart';
import 'package:subsy/features/subscription_import/domain/ocr_service.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';
import 'package:subsy/features/subscription_import/domain/pdf_picker_port.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscription_import/domain/subscription_parser.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/premium_status.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/subscription_draft.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';

/// Steps of the import flow (contracts/import-flow.md).
enum ImportStatus { idle, locked, recognizing, review, noResult, error, saving, done }

/// Immutable UI state for the import flow.
@immutable
class ImportState {
  const ImportState({
    this.status = ImportStatus.idle,
    this.drafts = const [],
    this.draftErrors = const [],
    this.selected = const [],
    this.errorMessage,
    this.savedCount = 0,
  });

  final ImportStatus status;
  final List<RecognizedDraft> drafts;

  /// Per-draft error message (parallel to [drafts]); null when valid.
  final List<String?> draftErrors;

  /// Per-draft selection (parallel to [drafts]); duplicates start unchecked.
  final List<bool> selected;
  final String? errorMessage;
  final int savedCount;

  /// Number of drafts currently checked for saving.
  int get selectedCount => selected.where((e) => e).length;

  /// Whether every draft is checked.
  bool get allSelected => drafts.isNotEmpty && selected.every((e) => e);

  ImportState copyWith({
    ImportStatus? status,
    List<RecognizedDraft>? drafts,
    List<String?>? draftErrors,
    List<bool>? selected,
    String? errorMessage,
    bool clearError = false,
    int? savedCount,
  }) {
    return ImportState(
      status: status ?? this.status,
      drafts: drafts ?? this.drafts,
      draftErrors: draftErrors ?? this.draftErrors,
      selected: selected ?? this.selected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedCount: savedCount ?? this.savedCount,
    );
  }
}

/// Orchestrates pick → OCR → parse → dedupe → review → save. Premium-gated.
/// Plain [ChangeNotifier] so it is unit-testable with fakes (mirrors
/// `SubscriptionFormController`); all spending rules stay in `AddSubscription`.
class ImportController extends ChangeNotifier {
  ImportController({
    required OcrService ocr,
    required AddSubscription add,
    required PremiumStatus premium,
    required List<Subscription> Function() readSubscriptions,
    required DateTime Function() now,
    ImagePickerPort? picker,
    PdfPickerPort? pdfPicker,
    SubscriptionParser parser = const SubscriptionParser(),
    DuplicateDetector duplicateDetector = const DuplicateDetector(),
  })  : _ocr = ocr,
        _add = add,
        _premium = premium,
        _readSubscriptions = readSubscriptions,
        _now = now,
        _picker = picker,
        _pdfPicker = pdfPicker,
        _parser = parser,
        _duplicates = duplicateDetector;

  final OcrService _ocr;
  final AddSubscription _add;
  final PremiumStatus _premium;
  final List<Subscription> Function() _readSubscriptions;
  final DateTime Function() _now;
  final ImagePickerPort? _picker;
  final PdfPickerPort? _pdfPicker;
  final SubscriptionParser _parser;
  final DuplicateDetector _duplicates;

  ImportState _state = const ImportState();
  ImportState get state => _state;

  void _set(ImportState next) {
    _state = next;
    notifyListeners();
  }

  /// Re-reads premium status. Free users are gated to a locked teaser with no
  /// OCR ever run (FR-017/FR-018). Call when the flow opens.
  void open() {
    if (!_premium.isPremium) {
      _set(const ImportState(status: ImportStatus.locked));
    } else {
      _set(const ImportState(status: ImportStatus.idle));
    }
  }

  Future<void> importFromGallery() => _pickAndRecognize(ImportImageSource.gallery);
  Future<void> importFromCamera() => _pickAndRecognize(ImportImageSource.camera);

  Future<void> _pickAndRecognize(ImportImageSource source) async {
    if (!_premium.isPremium) {
      _set(const ImportState(status: ImportStatus.locked));
      return;
    }
    final picker = _picker;
    if (picker == null) return;
    final Uint8List? bytes;
    try {
      bytes = await picker.pick(source);
    } catch (_) {
      _set(const ImportState(
        status: ImportStatus.error,
        errorMessage: 'Görsele erişilemedi. İzinleri kontrol edip tekrar deneyin.',
      ));
      return;
    }
    if (bytes == null) return; // user cancelled — stay idle
    await _recognize(() => _ocr.recognizeImage(bytes!));
  }

  /// PDF receipt import (US4): pick a PDF → extract/recognize → review.
  Future<void> importFromPdf() async {
    if (!_premium.isPremium) {
      _set(const ImportState(status: ImportStatus.locked));
      return;
    }
    final picker = _pdfPicker;
    if (picker == null) return;
    final Uint8List? bytes;
    try {
      bytes = await picker.pickPdf();
    } catch (_) {
      _set(const ImportState(
        status: ImportStatus.error,
        errorMessage: 'PDF açılamadı. Lütfen tekrar deneyin.',
      ));
      return;
    }
    if (bytes == null) return;
    await _recognize(() => _ocr.recognizePdf(bytes!));
  }

  /// Core orchestration: OCR → parse → dedupe → review. Testable directly with
  /// canned bytes + a fake [OcrService] (no device).
  Future<void> recognize(Uint8List bytes) =>
      _recognize(() => _ocr.recognizeImage(bytes));

  Future<void> _recognize(Future<OcrText> Function() run) async {
    if (!_premium.isPremium) {
      _set(const ImportState(status: ImportStatus.locked));
      return;
    }
    _set(const ImportState(status: ImportStatus.recognizing));
    try {
      final text = await run();
      _produceDrafts(_parser.parse(text, now: _now()));
    } catch (_) {
      _set(const ImportState(
        status: ImportStatus.error,
        errorMessage: 'Görsel okunamadı. Lütfen tekrar deneyin.',
      ));
    }
  }

  void _produceDrafts(List<RecognizedDraft> parsed) {
    if (parsed.isEmpty) {
      _set(const ImportState(status: ImportStatus.noResult));
      return;
    }
    final existing = _readSubscriptions();
    final flagged = parsed
        .map((d) => d.copyWith(duplicateOf: _duplicates.findDuplicate(d, existing)))
        .toList();
    _set(ImportState(
      status: ImportStatus.review,
      drafts: flagged,
      draftErrors: List<String?>.filled(flagged.length, null),
      // Possible duplicates start unchecked so they aren't saved by accident.
      selected: [for (final d in flagged) d.duplicateOf == null],
    ));
  }

  /// Toggle one draft's checkbox.
  void toggleSelected(int index) {
    if (index < 0 || index >= _state.selected.length) return;
    final selected = List<bool>.of(_state.selected)..[index] = !_state.selected[index];
    _set(_state.copyWith(selected: selected));
  }

  /// Check or uncheck every draft.
  void setAllSelected(bool value) {
    _set(_state.copyWith(selected: List<bool>.filled(_state.drafts.length, value)));
  }

  void editDraft(int index, RecognizedDraft updated) {
    if (index < 0 || index >= _state.drafts.length) return;
    final drafts = List<RecognizedDraft>.of(_state.drafts)..[index] = updated;
    final errors = List<String?>.of(_state.draftErrors)..[index] = null;
    _set(_state.copyWith(drafts: drafts, draftErrors: errors));
  }

  void discardDraft(int index) {
    if (index < 0 || index >= _state.drafts.length) return;
    final drafts = List<RecognizedDraft>.of(_state.drafts)..removeAt(index);
    final errors = List<String?>.of(_state.draftErrors)..removeAt(index);
    final selected = List<bool>.of(_state.selected)..removeAt(index);
    if (drafts.isEmpty) {
      _set(const ImportState(status: ImportStatus.idle));
    } else {
      _set(_state.copyWith(drafts: drafts, draftErrors: errors, selected: selected));
    }
  }

  /// Saves only the checked drafts through `AddSubscription`. Unchecked drafts
  /// are dropped. On full success → done; if a checked draft is invalid or its
  /// save fails, only those stay in review with a Turkish message for a retry.
  Future<void> confirmSelected() async {
    _set(_state.copyWith(status: ImportStatus.saving, clearError: true));
    final keptDrafts = <RecognizedDraft>[];
    final keptErrors = <String?>[];
    var saved = 0;

    for (var i = 0; i < _state.drafts.length; i++) {
      final isSelected = i < _state.selected.length && _state.selected[i];
      if (!isSelected) continue;
      final draft = _state.drafts[i];
      if (!draft.isComplete) {
        keptDrafts.add(draft);
        keptErrors.add('Eksik alanları doldurun (tutar, para birimi, tarih).');
        continue;
      }
      final result = await _add(_toDraft(draft));
      switch (result) {
        case Success<Subscription>():
          saved++;
        case Failure<Subscription>(:final error):
          keptDrafts.add(draft);
          keptErrors.add(error.message);
      }
    }

    if (keptDrafts.isEmpty) {
      _set(ImportState(status: ImportStatus.done, savedCount: saved));
    } else {
      _set(ImportState(
        status: ImportStatus.review,
        drafts: keptDrafts,
        draftErrors: keptErrors,
        selected: List<bool>.filled(keptDrafts.length, true),
        savedCount: saved,
      ));
    }
  }

  /// Saves each draft through `AddSubscription`. Incomplete/invalid drafts are
  /// kept in review with a Turkish message; valid ones are saved. Nothing is
  /// saved without this explicit call (FR-005).
  Future<void> confirmAll() async {
    _set(_state.copyWith(status: ImportStatus.saving, clearError: true));
    final remaining = <RecognizedDraft>[];
    final remainingErrors = <String?>[];
    var saved = 0;

    for (final draft in _state.drafts) {
      if (!draft.isComplete) {
        remaining.add(draft);
        remainingErrors.add('Eksik alanları doldurun (tutar, para birimi, tarih).');
        continue;
      }
      final result = await _add(_toDraft(draft));
      switch (result) {
        case Success<Subscription>():
          saved++;
        case Failure<Subscription>(:final error):
          remaining.add(draft);
          remainingErrors.add(error.message);
      }
    }

    if (remaining.isEmpty) {
      _set(ImportState(status: ImportStatus.done, savedCount: saved));
    } else {
      _set(ImportState(
        status: ImportStatus.review,
        drafts: remaining,
        draftErrors: remainingErrors,
        savedCount: saved,
      ));
    }
  }

  void reset() => _set(const ImportState());

  SubscriptionDraft _toDraft(RecognizedDraft d) => SubscriptionDraft(
        name: d.name.trim(),
        amount: d.amount!,
        currency: d.currency!,
        billingPeriod: d.billingPeriod ?? BillingPeriod.monthly,
        nextRenewalDate: d.nextRenewalDate!,
        category: d.category,
      );
}
