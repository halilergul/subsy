import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// TEMP: shows a "Premium (test)" switch so the premium UI can be previewed
/// before the RevenueCat paywall ships. Remove with the paywall feature.
const bool _kShowDebugPremiumToggle = true;

/// Ayarlar — Liquid-Glass settings. A gold premium banner over grouped glass
/// lists (reminders, appearance, about) + the dev premium toggle. Lives in the
/// shell; no app bar of its own.
class GlassSettings extends ConsumerWidget {
  const GlassSettings({super.key, this.onPaywall});

  final VoidCallback? onPaywall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final reminders = ref.watch(notificationSettingsProvider).asData?.value;
    final topInset = MediaQuery.paddingOf(context).top + 14;

    final String reminderDetail;
    if (reminders == null || !reminders.enabled) {
      reminderDetail = 'Kapalı';
    } else {
      reminderDetail =
          reminders.leadDays == 0 ? 'Yenileme günü' : '${reminders.leadDays} gün önce';
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(18, topInset, 18, 128),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text('Ayarlar',
              style: AppText.largeTitle.copyWith(color: AppTokens.text)),
        ),
        _PremiumBanner(isPremium: isPremium, onTap: onPaywall),
        const SizedBox(height: 22),
        const _Label('Genel'),
        const SizedBox(height: 10),
        _Group([
          _Row(
            icon: Icons.notifications_none_rounded,
            iconColor: AppTokens.amber,
            title: 'Bildirimler',
            detail: reminderDetail,
            onTap: () => context.push(Routes.notificationSettings),
            last: true,
          ),
        ]),
        const SizedBox(height: 18),
        const _Label('Arayüz'),
        const SizedBox(height: 10),
        _Group([
          const _Row(
            icon: Icons.dark_mode_outlined,
            iconColor: AppTokens.accent,
            title: 'Görünüm',
            detail: 'Koyu',
          ),
          _Row(
            icon: Icons.widgets_outlined,
            iconColor: AppTokens.green,
            title: "Ana Ekran Widget'ı",
            detail: isPremium ? 'Açık' : 'Premium',
            last: true,
          ),
        ]),
        const SizedBox(height: 18),
        const _Label('Hakkında'),
        const SizedBox(height: 10),
        _Group([
          _Row(
            icon: Icons.slideshow_outlined,
            iconColor: AppTokens.accent,
            title: 'Tanıtımı Tekrar Göster',
            onTap: () => context.push(Routes.onboarding),
          ),
          const _Row(
            icon: Icons.lock_outline,
            iconColor: AppTokens.green,
            title: 'Gizlilik',
            detail: 'Cihazında',
          ),
          const _Row(
            icon: Icons.info_outline,
            iconColor: AppTokens.muted,
            title: 'Sürüm',
            detail: '1.0.0',
            last: true,
          ),
        ]),
        if (_kShowDebugPremiumToggle) ...[
          const SizedBox(height: 18),
          const _Label('Geliştirici'),
          const SizedBox(height: 10),
          _Group([const _DebugPremiumRow()]),
        ],
      ],
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.isPremium, this.onTap});

  final bool isPremium;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTokens.accentGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color.fromRGBO(199, 162, 86, 0.4),
                blurRadius: 28,
                offset: Offset(0, 10)),
          ],
        ),
        child: _content(
          iconBg: const Color.fromRGBO(0, 0, 0, 0.16),
          iconColor: AppTokens.onAccent,
          titleColor: AppTokens.onAccent,
          subColor: const Color.fromRGBO(26, 20, 5, 0.7),
          sub: 'Tüm özellikler açık',
          chevron: false,
        ),
      );
    }
    return GlassSurface(
      radius: 22,
      fill: GlassFill.strong,
      shadow: AppTokens.glassShadow,
      onTap: onTap,
      child: _content(
        iconBg: const Color.fromRGBO(199, 162, 86, 0.16),
        iconColor: AppTokens.accentFg,
        titleColor: AppTokens.text,
        subColor: AppTokens.muted,
        sub: 'Kur çevirisi, widget ve birleşik istatistik',
        chevron: true,
      ),
    );
  }

  Widget _content({
    required Color iconBg,
    required Color iconColor,
    required Color titleColor,
    required Color subColor,
    required String sub,
    required bool chevron,
  }) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.auto_awesome, size: 23, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subsy Premium',
                    style: AppText.headline.copyWith(color: titleColor)),
                const SizedBox(height: 2),
                Text(sub, style: AppText.footnote.copyWith(color: subColor)),
              ],
            ),
          ),
          if (chevron)
            const Icon(Icons.chevron_right, size: 20, color: AppTokens.accentFg),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 18,
      fill: GlassFill.strong,
      child: Column(children: rows),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppTokens.hair, width: 0.5)),
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
                child: Text(title, style: AppText.body.copyWith(color: AppTokens.text)),
              ),
              if (detail != null)
                Text(detail!, style: AppText.subhead.copyWith(color: AppTokens.muted)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: AppTokens.tertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// TEMP debug row: toggles the premium stub at runtime to preview premium UI.
class _DebugPremiumRow extends ConsumerWidget {
  const _DebugPremiumRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(premiumOverrideProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTokens.accentFg.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                size: 18, color: AppTokens.accentFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text('Premium (test)',
                style: AppText.body.copyWith(color: AppTokens.text)),
          ),
          Switch.adaptive(
            value: on,
            activeThumbColor: AppTokens.accentFg,
            onChanged: (v) => ref.read(premiumOverrideProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: AppText.footnote.copyWith(
                color: AppTokens.muted, fontWeight: FontWeight.w600)),
      );
}
