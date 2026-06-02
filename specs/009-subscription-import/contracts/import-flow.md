# Contract: Import flow (ImportController + screens)

Orchestrates pick → OCR → parse → dedupe → review → save. Premium-gated. UI reads controller state via a provider; logic stays out of widgets.

## ImportController

```dart
class ImportController extends ... {
  // Sources
  Future<void> importFromGallery();   // image_picker (gallery)
  Future<void> importFromCamera();    // image_picker (camera)
  Future<void> importFromPdf();       // (US4) file_picker → recognizePdf
  void startAppStoreGuide();          // shows guidance, then importFromGallery (screenshot)

  // Review actions
  void editDraft(int index, RecognizedDraft updated);
  void discardDraft(int index);

  // Commit
  Future<void> confirmAll();          // each kept draft → SubscriptionDraft → AddSubscription
  void reset();
}
```

## State machine (`ImportStatus`)

```
idle ──(open, free user)──────────────► locked         (FR-017: teaser, no OCR)
idle ──(open, premium)────────────────► idle (sources shown)
idle ──(pick source)──► recognizing ──► review          (≥1 draft)
                                   └──► noResult         (0 drafts — FR-011)
                                   └──► error            (permission denied / engine fail — FR-012)
review ──(confirmAll)──► saving ──────► done (savedCount)
review ──(edit/discard)─► review
error/noResult ──(retry | manual entry)──► idle / form
```

## Step guarantees

1. **Gate first** (FR-017/FR-018): on open, read `premiumStatusProvider`. Free → `locked`, **no OCR runs**. Premium status re-read each open (downgrade reverts to locked).
2. **Pick** (D8): `image_picker` for gallery/camera; denial → `error` with Turkish message + retry/open-settings (FR-012). User cancel → back to `idle` (no error).
3. **Recognize** (D1): bytes → `ocrServiceProvider.recognizeImage`. Offline; transient (FR-016).
4. **Parse** (D3): `SubscriptionParser.parse(ocrText)` → drafts. Empty → `noResult` (FR-011).
5. **Dedupe** (FR-014): `DuplicateDetector` against current `subscriptionsProvider` value; set `duplicateOf` flags.
6. **Review** (US2): `review` state exposes editable drafts; nothing saved yet (FR-005). Every field editable; discard removes one without affecting others (FR-006).
7. **Confirm** (FR-009): for each kept draft → `SubscriptionDraft` → `AddSubscription`. Collect per-draft `Result`; a validation failure marks that draft (Turkish message) and leaves it in review; successes are saved. `savedCount` = successes → `done`.
8. **Transient**: controller holds no source bytes after recognition; `reset()` clears drafts.

## Screens

- **import_entry_screen.dart**: premium locked-teaser state *or* source options (Galeriden seç / Fotoğraf çek / PDF — US4 / App Store & Play aboneliklerim). Dark + Turkish. Routed at `'/subscription/import'`, reachable from the add/dashboard flow.
- **import_review_screen.dart**: list of draft cards — brand avatar + editable name/amount/currency/period/date/category, "kontrol et" markers on low-confidence fields, duplicate badge with skip/add, per-card discard, and a single "Hepsini kaydet" action → success summary.

## Testing (per quickstart)

- `import_controller_test.dart` with `FakeOcrService`: free→`locked` (no OCR); canned text→`review` with expected drafts; empty→`noResult`; fake throw→`error`; `confirmAll` calls `AddSubscription` per kept draft and reports `savedCount`.
- Parser/helpers tested separately (pure — see subscription-parser.md).
- ML Kit native render, permissions, PDF rasterization → device-verified, deferred (no device/Xcode here).
