import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscriptions/presentation/widgets/add_form_sheet.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

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

  /// Popular services shown when not searching (valid catalog keys, in order).
  static const _popular = [
    'netflix', 'spotify', 'youtube_premium', 'disney_plus',
    'apple_music', 'icloud_plus', 'chatgpt', 'claude_pro',
    'xbox_game_pass', 'storytel', 'nordvpn', 'microsoft_365',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BrandCatalogEntry> get _popularEntries {
    final byKey = {for (final e in kBrandCatalog) e.serviceKey: e};
    return [for (final k in _popular) if (byKey[k] != null) byKey[k]!];
  }

  List<BrandCatalogEntry> _matches(String q) {
    final n = q.toLowerCase();
    return kBrandCatalog.where((e) {
      if (e.displayName.toLowerCase().contains(n)) return true;
      return e.aliases.any((a) => a.toLowerCase().contains(n));
    }).toList();
  }

  Future<void> _openForm({BrandCatalogEntry? entry, String? initialName}) async {
    final saved = await showAddFormSheet(context, entry: entry, initialName: initialName);
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _scan() async {
    final saved = await context.push<bool>(Routes.importSubscription);
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim();
    final matches = q.isEmpty ? const <BrandCatalogEntry>[] : _matches(q);
    final grid = q.isEmpty ? _popularEntries : matches;
    final noMatch = q.isNotEmpty && matches.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                _header(),
                _search(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      if (noMatch) ...[
                        _searchCreateRow(q),
                        const SizedBox(height: 18),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 14),
                        child: Text(
                          q.isEmpty ? 'Popüler servisler' : 'Sonuçlar',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTokens.muted, letterSpacing: 0.3),
                        ),
                      ),
                      _grid(grid, showOther: q.isEmpty),
                    ],
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
        decoration: BoxDecoration(color: AppTokens.grabber, borderRadius: BorderRadius.circular(999)),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 10),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Abonelik ekle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTokens.text, letterSpacing: -0.2),
              ),
            ),
            Material(
              color: AppTokens.fill,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(width: 32, height: 32, child: Icon(Icons.close, size: 17, color: AppTokens.muted)),
              ),
            ),
          ],
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
          border: Border.all(color: const Color.fromRGBO(199, 162, 86, 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppTokens.surface2, shape: BoxShape.circle),
              child: const Icon(Icons.add, size: 20, color: AppTokens.accentFg),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text("'$q' olarak ekle",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppTokens.text)),
            ),
            const Icon(Icons.arrow_forward, size: 18, color: AppTokens.accentFg),
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
          BrandAvatar(serviceKey: e.serviceKey, fallbackName: e.displayName, size: 56, circle: true),
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
              border: Border.all(color: AppTokens.hair2, width: 1.5, style: BorderStyle.solid),
            ),
            child: const Icon(Icons.add, size: 22, color: AppTokens.muted),
          ),
          const SizedBox(height: 7),
          const Text('Diğer', style: TextStyle(fontSize: 11, color: AppTokens.muted)),
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
                side: const BorderSide(color: Color.fromRGBO(199, 162, 86, 0.4), width: 1),
              ),
              child: InkWell(
                onTap: _scan,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 19, color: AppTokens.accentFg),
                    SizedBox(width: 10),
                    Text('Dokümandan tara',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTokens.accentFg)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Makbuz, ekran görüntüsü veya App Store aboneliklerinden otomatik ekle',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTokens.tertiary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
