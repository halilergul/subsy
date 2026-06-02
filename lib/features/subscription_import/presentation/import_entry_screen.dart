import 'package:flutter/material.dart';

/// Source-picker view for the import flow (US1/US3). Shown when the user is
/// premium and no recognition is running.
class ImportEntryView extends StatelessWidget {
  const ImportEntryView({
    super.key,
    required this.onGallery,
    required this.onCamera,
    required this.onAppStore,
    this.onPdf,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  /// Guides the user to screenshot the system subscriptions screen, then picks
  /// that image (US3) — store subscriptions can't be read directly.
  final VoidCallback onAppStore;

  /// PDF receipt import (US4); null hides the option.
  final VoidCallback? onPdf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text('Aboneliği otomatik tanı', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Bir ekran görüntüsü, makbuz fotoğrafı ya da App Store / Play abonelik '
          'ekranından aboneliklerini otomatik ekle. Her şey cihazında işlenir — '
          'hiçbir veri dışarı çıkmaz.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 24),
        _SourceTile(
          icon: Icons.photo_library_outlined,
          title: 'Galeriden seç',
          subtitle: 'Ekran görüntüsü veya kaydedilmiş makbuz',
          onTap: onGallery,
        ),
        _SourceTile(
          icon: Icons.photo_camera_outlined,
          title: 'Fotoğraf çek',
          subtitle: 'Kağıt makbuzu kamerayla tara',
          onTap: onCamera,
        ),
        _SourceTile(
          icon: Icons.apple_outlined,
          title: 'App Store / Play aboneliklerim',
          subtitle: 'Sistem abonelik ekranının görüntüsünden içe aktar',
          onTap: () => _showAppStoreGuide(context),
        ),
        if (onPdf != null)
          _SourceTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF içe aktar',
            subtitle: 'Fatura / makbuz PDF dosyası',
            onTap: onPdf!,
          ),
      ],
    );
  }

  void _showAppStoreGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Store / Play aboneliklerin',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text(
              'Uygulamalar, mağaza aboneliklerini doğrudan okuyamaz. Bunun yerine '
              'sistem abonelik ekranını aç, ekran görüntüsü al ve burada seç:',
            ),
            const SizedBox(height: 12),
            const _GuideStep(n: '1', text: 'iOS: Ayarlar → Apple Kimliği → Abonelikler'),
            const _GuideStep(n: '2', text: 'Android: Play Store → Abonelikler'),
            const _GuideStep(n: '3', text: 'Ekran görüntüsü al, sonra galeriden seç'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                onAppStore();
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Ekran görüntüsünü seç'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Locked teaser for free users — no recognition runs (FR-017, US5).
class ImportLockedView extends StatelessWidget {
  const ImportLockedView({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Otomatik tanıma Premium', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Makbuz, ekran görüntüsü ve App Store aboneliklerinden otomatik '
              'abonelik ekleme Premium ile gelir. Aboneliklerini elle eklemek '
              'her zaman ücretsiz.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onUpgrade, child: const Text('Premium’a geç')),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text(n, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
