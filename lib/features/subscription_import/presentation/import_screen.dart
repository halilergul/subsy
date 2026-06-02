import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/subscription_import/application/import_controller.dart';
import 'package:subsy/features/subscription_import/application/subscription_import_providers.dart';
import 'package:subsy/features/subscription_import/presentation/import_entry_screen.dart';
import 'package:subsy/features/subscription_import/presentation/import_review_screen.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$n abonelik eklendi.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium satın alma yakında.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Otomatik ekle')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _body(_controller.state),
      ),
    );
  }

  Widget _body(ImportState state) {
    return switch (state.status) {
      ImportStatus.locked => ImportLockedView(onUpgrade: _comingSoon),
      ImportStatus.recognizing => const _Busy(label: 'Görsel okunuyor…'),
      ImportStatus.saving => ImportReviewView(
          state: state,
          onChanged: _controller.editDraft,
          onDiscard: _controller.discardDraft,
          onConfirm: _controller.confirmAll,
        ),
      ImportStatus.review => ImportReviewView(
          state: state,
          onChanged: _controller.editDraft,
          onDiscard: _controller.discardDraft,
          onConfirm: _controller.confirmAll,
        ),
      ImportStatus.noResult => _Message(
          icon: Icons.search_off,
          title: 'Abonelik bulunamadı',
          body: 'Bu görselde tanınabilir bir abonelik yok. Daha net bir görsel '
              'deneyebilir ya da elle ekleyebilirsin.',
          onRetry: _controller.open,
        ),
      ImportStatus.error => _Message(
          icon: Icons.error_outline,
          title: 'Bir sorun oluştu',
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    );
  }
}
