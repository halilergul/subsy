import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/subscription_import/application/import_controller.dart';
import 'package:subsy/features/subscription_import/domain/ocr_text.dart';
import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/domain/usecases/add_subscription.dart';

import '../support/fakes.dart';

void main() {
  final now = DateTime(2026, 6, 1);
  final bytes = Uint8List.fromList([1, 2, 3]);

  late FakeSubscriptionRepository repo;
  late FakePremium premium;
  late FakeOcrService ocr;
  late FakeImagePickerPort picker;

  ImportController build() {
    final add = AddSubscription(repo, premium, const BrandResolver());
    return ImportController(
      ocr: ocr,
      add: add,
      premium: premium,
      readSubscriptions: () => repo.items,
      now: () => now,
      picker: picker,
    );
  }

  setUp(() {
    repo = FakeSubscriptionRepository();
    premium = FakePremium(true);
    ocr = FakeOcrService(
      canned: const OcrText(lines: [
        'Spotify Premium',
        '₺59,99 / ay',
        'Sonraki ödeme: 12.06.2026',
      ]),
    );
    picker = FakeImagePickerPort(bytes: Uint8List.fromList([9]));
  });

  group('US1 — recognize', () {
    test('canned text → review with a pre-filled draft', () async {
      final c = build();
      await c.recognize(bytes);
      expect(c.state.status, ImportStatus.review);
      final d = c.state.drafts.single;
      expect(d.serviceKey, 'spotify');
      expect(d.amount, 59.99);
      expect(d.currency, Currency.tryl);
      expect(d.nextRenewalDate, DateTime(2026, 6, 12));
    });

    test('empty recognition → noResult', () async {
      ocr.canned = OcrText.empty;
      final c = build();
      await c.recognize(bytes);
      expect(c.state.status, ImportStatus.noResult);
    });

    test('OCR engine failure → error', () async {
      ocr.throwError = true;
      final c = build();
      await c.recognize(bytes);
      expect(c.state.status, ImportStatus.error);
      expect(c.state.errorMessage, isNotNull);
    });

    test('confirmAll saves valid drafts and reports savedCount', () async {
      final c = build();
      await c.recognize(bytes);
      await c.confirmAll();
      expect(c.state.status, ImportStatus.done);
      expect(c.state.savedCount, 1);
      expect(repo.items.single.serviceKey, 'spotify');
    });
  });

  group('US2 — review & correct', () {
    test('edit a field then confirm saves the edited value', () async {
      final c = build();
      await c.recognize(bytes);
      final edited = c.state.drafts.single.copyWith(amount: 79.99);
      c.editDraft(0, edited);
      await c.confirmAll();
      expect(repo.items.single.amount, 79.99);
    });

    test('incomplete draft is blocked at confirm with a message', () async {
      ocr.canned = const OcrText(lines: ['Spotify Premium ₺59,99']); // no date
      final c = build();
      await c.recognize(bytes);
      expect(c.state.drafts.single.isComplete, isFalse);
      await c.confirmAll();
      expect(c.state.status, ImportStatus.review);
      expect(c.state.savedCount, 0);
      expect(c.state.draftErrors.single, isNotNull);
    });

    test('discard removes a draft without affecting others', () async {
      ocr.canned = const OcrText(lines: [
        'Netflix',
        '₺149,99 Aylık',
        'Spotify',
        '₺59,99 Aylık',
      ]);
      final c = build();
      await c.recognize(bytes);
      expect(c.state.drafts, hasLength(2));
      c.discardDraft(0);
      expect(c.state.drafts.single.serviceKey, 'spotify');
    });

    test('duplicate is flagged against existing subscriptions', () async {
      repo.items.add(Subscription(
        id: 1,
        name: 'Spotify',
        serviceKey: 'spotify',
        amount: 59.99,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: now,
        category: SubscriptionCategory.music,
        createdAt: now,
        updatedAt: now,
      ));
      final c = build();
      await c.recognize(bytes);
      expect(c.state.drafts.single.duplicateOf, 'Spotify');
    });
  });

  group('US5 — premium gating', () {
    test('free user → locked, no OCR runs (SC-008)', () async {
      premium = FakePremium(false);
      final c = build();
      c.open();
      expect(c.state.status, ImportStatus.locked);
      await c.importFromGallery();
      expect(c.state.status, ImportStatus.locked);
      expect(ocr.recognizeImageCount, 0);
      expect(picker.pickCount, 0);
    });

    test('premium user proceeds through the flow', () async {
      final c = build();
      c.open();
      expect(c.state.status, ImportStatus.idle);
      await c.importFromGallery();
      expect(c.state.status, ImportStatus.review);
      expect(ocr.recognizeImageCount, 1);
    });

    test('image permission denied → error', () async {
      picker = FakeImagePickerPort(throwError: true);
      final c = build();
      await c.importFromGallery();
      expect(c.state.status, ImportStatus.error);
    });
  });

  group('US4 — PDF import', () {
    test('picks a PDF, recognizes via recognizePdf, → review', () async {
      final pdf = FakePdfPickerPort(bytes: Uint8List.fromList([7]));
      final add = AddSubscription(repo, premium, const BrandResolver());
      final c = ImportController(
        ocr: ocr, // canned Spotify text, used by recognizePdf too
        add: add,
        premium: premium,
        readSubscriptions: () => repo.items,
        now: () => now,
        pdfPicker: pdf,
      );
      await c.importFromPdf();
      expect(pdf.pickCount, 1);
      expect(ocr.recognizePdfCount, 1);
      expect(c.state.status, ImportStatus.review);
      expect(c.state.drafts.single.serviceKey, 'spotify');
    });

    test('free user → locked, no PDF picked', () async {
      premium = FakePremium(false);
      final pdf = FakePdfPickerPort(bytes: Uint8List.fromList([7]));
      final add = AddSubscription(repo, premium, const BrandResolver());
      final c = ImportController(
        ocr: ocr,
        add: add,
        premium: premium,
        readSubscriptions: () => repo.items,
        now: () => now,
        pdfPicker: pdf,
      );
      await c.importFromPdf();
      expect(c.state.status, ImportStatus.locked);
      expect(pdf.pickCount, 0);
    });
  });

  test('helper: RecognizedDraft.isComplete', () {
    const d = RecognizedDraft(name: 'X');
    expect(d.isComplete, isFalse);
  });

  group('US2 — selection model', () {
    final t = DateTime(2026, 1, 1);
    Subscription netflixSub() => Subscription(
          id: 1,
          name: 'Netflix',
          serviceKey: 'netflix',
          amount: 149.99,
          currency: Currency.tryl,
          billingPeriod: BillingPeriod.monthly,
          nextRenewalDate: now,
          category: SubscriptionCategory.streaming,
          createdAt: t,
          updatedAt: t,
        );

    void useTwoDrafts() {
      ocr = FakeOcrService(
        canned: const OcrText(lines: [
          'Netflix ₺149,99 Aylık 12.06.2026',
          'Spotify ₺59,99 Aylık 15.06.2026',
        ]),
      );
    }

    test('possible duplicates start unchecked, others checked', () async {
      useTwoDrafts();
      repo.items.add(netflixSub()); // makes the Netflix draft a duplicate
      final c = build();
      await c.recognize(bytes);

      expect(c.state.status, ImportStatus.review);
      expect(c.state.drafts, hasLength(2));
      final netflix = c.state.drafts.indexWhere((d) => d.serviceKey == 'netflix');
      final spotify = c.state.drafts.indexWhere((d) => d.serviceKey == 'spotify');
      expect(c.state.selected[netflix], isFalse); // duplicate pre-unchecked
      expect(c.state.selected[spotify], isTrue);
      expect(c.state.selectedCount, 1);
    });

    test('confirmSelected saves only the checked drafts', () async {
      useTwoDrafts();
      repo.items.add(netflixSub());
      final c = build();
      await c.recognize(bytes);

      await c.confirmSelected(); // only Spotify is checked
      expect(c.state.status, ImportStatus.done);
      expect(c.state.savedCount, 1);
      expect(repo.items.any((s) => s.serviceKey == 'spotify'), isTrue);
      expect(repo.items.where((s) => s.serviceKey == 'netflix'), hasLength(1)); // not re-added
    });

    test('toggleAll then toggle one saves exactly that draft', () async {
      useTwoDrafts();
      final c = build(); // no pre-existing duplicate → both checked
      await c.recognize(bytes);
      expect(c.state.selectedCount, 2);

      c.setAllSelected(false);
      expect(c.state.selectedCount, 0);
      c.toggleSelected(0);
      expect(c.state.selectedCount, 1);

      await c.confirmSelected();
      expect(c.state.savedCount, 1);
    });
  });
}
