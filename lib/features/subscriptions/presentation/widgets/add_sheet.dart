import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscription_import/presentation/import_screen.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_form_sheet.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass_app_bar.dart';

/// Opens the add-subscription entry sheet: a brand picker (search + popular
/// grid + "Diğer") with a pinned "scan a document" footer. Selecting a brand
/// (or Diğer / a search-create) opens the detail form sheet; a successful save
/// closes this sheet too, returning to the dashboard.
Future<void> showAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppTokens.scrim,
    builder: (_) => const _AddSheet(),
  );
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  /// When set, the sheet shows the detail form step (same sheet, no second
  /// modal); null = the brand-picker step.
  _FormTarget? _formTarget;

  /// Popular services shown when not searching (valid catalog keys, in order).
  static const _popular = [
    'netflix',
    'spotify',
    'youtube_premium',
    'disney_plus',
    'apple_music',
    'icloud_plus',
    'chatgpt',
    'claude_pro',
    'xbox_game_pass',
    'storytel',
    'nordvpn',
    'microsoft_365',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BrandCatalogEntry> get _popularEntries {
    final byKey = {for (final e in kBrandCatalog) e.serviceKey: e};
    return [
      for (final k in _popular)
        if (byKey[k] != null) byKey[k]!,
    ];
  }

  List<BrandCatalogEntry> _matches(String q) {
    final n = q.toLowerCase();
    return kBrandCatalog.where((e) {
      if (e.displayName.toLowerCase().contains(n)) return true;
      return e.aliases.any((a) => a.toLowerCase().contains(n));
    }).toList();
  }

  // Switch to the form step inside this same sheet (no second modal).
  void _openForm({BrandCatalogEntry? entry, String? initialName}) {
    setState(
      () => _formTarget = _FormTarget(entry: entry, initialName: initialName),
    );
  }

  /// Close this sheet first, then present the scan flow as its own full-height
  /// sheet from the dashboard — avoids stacking a second modal on top of this
  /// one. A successful import refreshes the dashboard reactively.
  Future<void> _scan() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await showImportSheet(navigator.context);
  }

  @override
  Widget build(BuildContext context) {
    // Form step — same sheet, with "Geri" back to the picker.
    final target = _formTarget;
    if (target != null) {
      return AddFormSheetShell(
        child: AddSubscriptionForm(
          entry: target.entry,
          initialName: target.initialName,
          onBack: () => setState(() => _formTarget = null),
          onClose: () => Navigator.of(context).pop(),
          onSaved: () => Navigator.of(context).pop(),
        ),
      );
    }

    final q = _q.trim();
    final matches = q.isEmpty ? const <BrandCatalogEntry>[] : _matches(q);
    final grid = q.isEmpty ? _popularEntries : matches;
    final noMatch = q.isNotEmpty && matches.isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppTokens.sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTokens.hair2, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _grabber(),
                GlassSheetHeader(
                  title: 'Abonelik Ekle',
                  onClose: () => Navigator.of(context).pop(),
                ),
                _search(),
                Expanded(
                  // Frost the list's top edge as it scrolls under the search —
                  // the same liquid-glass falloff used on the screens.
                  child: glassScrollBlur(
                    context,
                    bandHeight: 26,
                    sigma: 10,
                    backgroundColor: AppTokens.sheet,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        if (noMatch) ...[
                          _searchCreateRow(q),
                          const SizedBox(height: 18),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 14),
                          child: Text(
                            q.isEmpty ? 'Popüler Servisler' : 'Sonuçlar',
                            style: AppText.footnote.copyWith(
                              color: AppTokens.muted,
                            ),
                          ),
                        ),
                        _grid(grid, showOther: q.isEmpty),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grabber() => Container(
    margin: const EdgeInsets.only(top: 9, bottom: 4),
    width: 38,
    height: 5,
    decoration: BoxDecoration(
      color: AppTokens.grabber,
      borderRadius: BorderRadius.circular(999),
    ),
  );

  Widget _search() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTokens.fill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTokens.tertiary),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _q = v),
              style: const TextStyle(fontSize: 16, color: AppTokens.text),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Servis ara',
                hintStyle: TextStyle(color: AppTokens.tertiary),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _searchCreateRow(String q) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openForm(initialName: q),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(199, 162, 86, 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color.fromRGBO(199, 162, 86, 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTokens.surface2,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20, color: AppTokens.accentFg),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                "'$q' olarak ekle",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.text,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 18,
              color: AppTokens.accentFg,
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<BrandCatalogEntry> entries, {required bool showOther}) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 18,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (final e in entries) _brandTile(e),
        if (showOther) _otherTile(),
      ],
    );
  }

  Widget _brandTile(BrandCatalogEntry e) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openForm(entry: e),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandAvatar(
            serviceKey: e.serviceKey,
            fallbackName: e.displayName,
            size: 56,
            circle: true,
          ),
          const SizedBox(height: 7),
          Text(
            e.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTokens.muted),
          ),
        ],
      ),
    );
  }

  Widget _otherTile() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openForm(initialName: ''),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTokens.hair2,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(Icons.add, size: 22, color: AppTokens.muted),
          ),
          const SizedBox(height: 7),
          const Text(
            'Diğer',
            style: TextStyle(fontSize: 11, color: AppTokens.muted),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTokens.hair, width: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: const Color.fromRGBO(199, 162, 86, 0.12),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color.fromRGBO(199, 162, 86, 0.4),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: _scan,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 19,
                      color: AppTokens.accentFg,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Dokümandan Tara',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.accentFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Makbuz, ekran görüntüsü veya App Store aboneliklerinden otomatik ekle',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTokens.tertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The brand chosen in the picker step, carried into the form step.
class _FormTarget {
  const _FormTarget({this.entry, this.initialName});
  final BrandCatalogEntry? entry;
  final String? initialName;
}
