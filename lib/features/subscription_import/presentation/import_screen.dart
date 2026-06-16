import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscription_import/application/import_controller.dart';
import 'package:subsy/features/subscription_import/application/subscription_import_providers.dart';
import 'package:subsy/features/subscription_import/presentation/import_entry_screen.dart';
import 'package:subsy/features/subscription_import/presentation/import_review_screen.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/widgets/glass/glass_buttons.dart';
import 'package:subsy/shared/widgets/glass/glass_sheet.dart';

/// Presents the scan/import flow as a Liquid-Glass bottom sheet. Returns true
/// when at least one subscription was imported.
Future<bool?> showImportSheet(BuildContext context) {
  return showGlassSheet<bool>(context, builder: (_) => const ImportScreen());
}

/// Hosts the import flow: owns the [ImportController] and renders the right view
/// for each [ImportStatus] (entry / locked / recognizing / review / noResult /
/// error / done). Recognition + saving logic lives entirely in the controller.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  late final ImportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImportController(
      ocr: ref.read(ocrServiceProvider),
      add: ref.read(addSubscriptionProvider),
      premium: ref.read(premiumStatusProvider),
      readSubscriptions: () => ref.read(subscriptionsProvider).value ?? const [],
      now: DateTime.now,
      picker: ref.read(imagePickerPortProvider),
      pdfPicker: ref.read(pdfPickerPortProvider),
    );
    _controller.addListener(_onChange);
    _controller.open();
  }

  void _onChange() {
    if (!mounted) return;
    if (_controller.state.status == ImportStatus.done) {
      final n = _controller.state.savedCount;
      Navigator.of(context).pop(true);
      showGlassToast(context, '$n abonelik eklendi.');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _comingSoon() => showGlassToast(context, 'Premium satın alma yakında.');

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      title: 'Otomatik Ekle',
      onClose: () => Navigator.of(context).pop(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _body(_controller.state),
      ),
    );
  }

  Widget _body(ImportState state) {
    return switch (state.status) {
      ImportStatus.locked => ImportLockedView(onUpgrade: _comingSoon),
      ImportStatus.recognizing => const _Busy(label: 'Görsel okunuyor…'),
      ImportStatus.saving || ImportStatus.review => ImportReviewView(
        state: state,
        onChanged: _controller.editDraft,
        onDiscard: _controller.discardDraft,
        onToggleSelected: _controller.toggleSelected,
        onToggleAll: _controller.setAllSelected,
        onConfirm: _controller.confirmSelected,
      ),
      ImportStatus.noResult => _Message(
        icon: Icons.search_off_rounded,
        title: 'Abonelik Bulunamadı',
        body:
            'Bu görselde tanınabilir bir abonelik yok. Daha net bir görsel '
            'deneyebilir ya da elle ekleyebilirsin.',
        onRetry: _controller.open,
      ),
      ImportStatus.error => _Message(
        icon: Icons.error_outline_rounded,
        title: 'Bir Sorun Oluştu',
        body: state.errorMessage ?? 'Tekrar deneyin.',
        onRetry: _controller.open,
      ),
      ImportStatus.idle || ImportStatus.done => ImportEntryView(
        onGallery: _controller.importFromGallery,
        onCamera: _controller.importFromCamera,
        onAppStore: _controller.importFromGallery,
        onPdf: _controller.importFromPdf,
      ),
    };
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTokens.accentFg),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 14, color: AppTokens.muted)),
            const SizedBox(height: 6),
            const Text('Cihaz-üstü işleme · çevrimdışı',
                style: TextStyle(fontSize: 12, color: AppTokens.tertiary)),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppTokens.tertiary),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppTokens.text)),
          const SizedBox(height: 8),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTokens.muted, height: 1.45)),
          const SizedBox(height: 24),
          GoldButton(label: 'Tekrar Dene', onTap: onRetry),
        ],
      ),
    );
  }
}
