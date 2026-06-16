import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/glass/glass_buttons.dart';
import 'package:subsy/shared/widgets/glass/glass_sheet.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Aboneliği Otomatik Tanı',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTokens.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bir ekran görüntüsü, makbuz fotoğrafı ya da App Store / Play abonelik '
          'ekranından aboneliklerini otomatik ekle.',
          style: TextStyle(fontSize: 14, color: AppTokens.muted, height: 1.45),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.shield_outlined, size: 15, color: AppTokens.green),
            const SizedBox(width: 7),
            Expanded(
              child: Text('Her şey cihazında işlenir — hiçbir veri dışarı çıkmaz.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: AppTokens.green.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _SourceTile(
          icon: Icons.photo_library_outlined,
          color: AppTokens.accent,
          title: 'Galeriden Seç',
          subtitle: 'Ekran görüntüsü veya kaydedilmiş makbuz',
          onTap: onGallery,
        ),
        _SourceTile(
          icon: Icons.photo_camera_outlined,
          color: const Color(0xFF3E63DD),
          title: 'Fotoğraf Çek',
          subtitle: 'Kağıt makbuzu kamerayla tara',
          onTap: onCamera,
        ),
        _SourceTile(
          icon: Icons.storefront_outlined,
          color: const Color(0xFF12A594),
          title: 'App Store / Play aboneliklerim',
          subtitle: 'Sistem abonelik ekranının görüntüsünden içe aktar',
          onTap: () => _showAppStoreGuide(context),
        ),
        if (onPdf != null)
          _SourceTile(
            icon: Icons.picture_as_pdf_outlined,
            color: const Color(0xFFE5484D),
            title: 'PDF İçe Aktar',
            subtitle: 'Fatura / makbuz PDF dosyası',
            onTap: onPdf!,
          ),
        ],
      ),
    );
  }

  void _showAppStoreGuide(BuildContext context) {
    showGlassSheet<void>(
      context,
      builder: (ctx) => GlassSheet(
        title: 'App Store / Play Aboneliklerin',
        onClose: () => Navigator.of(ctx).pop(),
        contentHeight: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uygulamalar, mağaza aboneliklerini doğrudan okuyamaz. Bunun yerine '
                'sistem abonelik ekranını aç, ekran görüntüsü al ve burada seç:',
                style: TextStyle(fontSize: 14, color: AppTokens.muted, height: 1.45),
              ),
              const SizedBox(height: 16),
              const _GuideStep(n: '1', text: 'iOS: Ayarlar → Apple Kimliği → Abonelikler'),
              const _GuideStep(n: '2', text: 'Android: Play Store → Abonelikler'),
              const _GuideStep(n: '3', text: 'Ekran görüntüsü al, sonra galeriden seç'),
              const SizedBox(height: 20),
              GoldButton(
                label: 'Ekran Görüntüsünü Seç',
                icon: Icons.photo_library_outlined,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAppStore();
                },
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppTokens.accentGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Color.fromRGBO(199, 162, 86, 0.45),
                    blurRadius: 36,
                    offset: Offset(0, 14)),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 34, color: AppTokens.onAccent),
          ),
          const SizedBox(height: 18),
          const Text(
            'Otomatik Tanıma Premium',
            style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700, color: AppTokens.text),
          ),
          const SizedBox(height: 8),
          const Text(
            'Makbuz, ekran görüntüsü ve App Store aboneliklerinden otomatik '
            'abonelik ekleme Premium ile gelir. Aboneliklerini elle eklemek '
            'her zaman ücretsiz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTokens.muted, height: 1.45),
          ),
          const SizedBox(height: 24),
          GoldButton(label: "Premium'a Geç", onTap: onUpgrade),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        radius: 16,
        fill: GlassFill.soft,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTokens.muted, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: AppTokens.tertiary),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.accentFg.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppTokens.accentFg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: AppTokens.text, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}
