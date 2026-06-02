import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/widgets/glass_app_bar.dart';

/// App settings: a premium banner plus grouped rows for the real, on-device
/// settings (reminders, appearance, replaying onboarding, app info). No fake
/// toggles — every row maps to something that exists. Dark, gold-accented.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final reminders = ref.watch(notificationSettingsProvider).asData?.value;

    final String reminderDetail;
    if (reminders == null || !reminders.enabled) {
      reminderDetail = 'Kapalı';
    } else {
      reminderDetail = reminders.leadDays == 0 ? 'Yenileme günü' : '${reminders.leadDays} gün önce';
    }

    return Scaffold(
      backgroundColor: AppTokens.bg,
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(context, title: 'Ayarlar'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, glassTopInset(context), 20, 32),
        children: [
          _PremiumBanner(isPremium: isPremium),
          const SizedBox(height: 22),
          const _SectionLabel('Genel'),
          _group([
            _SettingRow(
              icon: Icons.notifications_none_rounded,
              iconColor: AppTokens.amber,
              title: 'Bildirimler',
              detail: reminderDetail,
              onTap: () => context.push(Routes.notificationSettings),
              last: true,
            ),
          ]),
          const SizedBox(height: 18),
          const _SectionLabel('Arayüz'),
          _group([
            const _SettingRow(
              icon: Icons.dark_mode_outlined,
              iconColor: AppTokens.accent,
              title: 'Görünüm',
              detail: 'Koyu',
            ),
            _SettingRow(
              icon: Icons.widgets_outlined,
              iconColor: AppTokens.green,
              title: "Ana ekran widget'ı",
              detail: isPremium ? 'Açık' : 'Premium',
              onTap: () => _info(context, 'Ana ekran widget\'ı premium ile birlikte gelir.'),
              last: true,
            ),
          ]),
          const SizedBox(height: 18),
          const _SectionLabel('Hakkında'),
          _group([
            _SettingRow(
              icon: Icons.slideshow_outlined,
              iconColor: AppTokens.accent,
              title: 'Tanıtımı tekrar göster',
              onTap: () => context.push(Routes.onboarding),
            ),
            const _SettingRow(
              icon: Icons.lock_outline,
              iconColor: AppTokens.green,
              title: 'Gizlilik',
              detail: 'Cihazında',
            ),
            const _SettingRow(
              icon: Icons.info_outline,
              iconColor: AppTokens.muted,
              title: 'Sürüm',
              detail: '1.0.0',
              last: true,
            ),
          ]),
        ],
      ),
    );
  }

  void _info(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPremium
            ? null
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium yakında geliyor.')),
                ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isPremium ? AppTokens.accentGradient : null,
            color: isPremium ? null : AppTokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPremium ? Colors.transparent : const Color.fromRGBO(199, 162, 86, 0.3),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isPremium ? AppTokens.onAccent.withValues(alpha: 0.15) : const Color.fromRGBO(199, 162, 86, 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, size: 22, color: isPremium ? AppTokens.onAccent : AppTokens.accentFg),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subsy Premium',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isPremium ? AppTokens.onAccent : AppTokens.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPremium ? 'Tüm özellikler açık' : 'Kur çevirisi, widget ve birleşik istatistik',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isPremium ? AppTokens.onAccent.withValues(alpha: 0.8) : AppTokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPremium) const Icon(Icons.chevron_right, size: 20, color: AppTokens.accentFg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTokens.muted, letterSpacing: 0.3)),
      );
}

Widget _group(List<Widget> rows) => Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Column(children: rows),
    );

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.detail,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppTokens.hair, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15.5, color: AppTokens.text)),
            ),
            if (detail != null)
              Text(detail!, style: const TextStyle(fontSize: 14.5, color: AppTokens.muted)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: AppTokens.tertiary),
            ],
          ],
        ),
      ),
    );
  }
}
