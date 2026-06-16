import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/widgets/glass/glass_buttons.dart';
import 'package:subsy/shared/widgets/glass/glass_sheet.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Opens the Liquid-Glass paywall sheet.
Future<void> showPaywallSheet(BuildContext context) {
  return showGlassSheet(context, builder: (_) => const GlassPaywallSheet());
}

/// Premium value-prop sheet. The purchase button currently flips the premium
/// stub (preview only) — the RevenueCat paywall replaces it later.
class GlassPaywallSheet extends ConsumerWidget {
  const GlassPaywallSheet({super.key});

  static const _features = [
    (Icons.add_rounded, 'Sınırsız abonelik'),
    (Icons.public, 'Döviz çevirisi ve birleşik ≈ toplam'),
    (Icons.document_scanner_outlined, 'Dokümandan otomatik tanıma (OCR)'),
    (Icons.widgets_outlined, "Ana ekran widget'ı"),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassSheet(
      title: 'Subsy Premium',
      onClose: () => Navigator.of(context).pop(),
      contentHeight: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold sparkle badge.
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
              child: const Icon(Icons.auto_awesome, size: 36, color: AppTokens.onAccent),
            ),
            const SizedBox(height: 18),
            Text(
              'Tek seferlik satın alımla tüm gelişmiş özellikleri aç. Verilerin yine cihazında kalır.',
              textAlign: TextAlign.center,
              style: AppText.subhead.copyWith(color: AppTokens.muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            GlassSurface(
              radius: 22,
              fill: GlassFill.soft,
              child: Column(
                children: [
                  for (var i = 0; i < _features.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: i > 0
                            ? const Border(
                                top: BorderSide(color: AppTokens.hair, width: 0.5))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(_features[i].$1, size: 19, color: AppTokens.accentFg),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(_features[i].$2,
                                style: AppText.subhead.copyWith(
                                    color: AppTokens.text, fontWeight: FontWeight.w600)),
                          ),
                          const Icon(Icons.check_rounded, size: 18, color: AppTokens.green),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GoldButton(
              label: '₺499,99 — Tek Seferlik Satın Al',
              onTap: () {
                ref.read(premiumOverrideProvider.notifier).set(true);
                Navigator.of(context).pop();
                showGlassToast(context, 'Premium etkin 🎉');
              },
            ),
            const SizedBox(height: 11),
            Text('Ömür boyu erişim · Abonelik değil',
                style: AppText.caption1.copyWith(color: AppTokens.tertiary)),
          ],
        ),
      ),
    );
  }
}
