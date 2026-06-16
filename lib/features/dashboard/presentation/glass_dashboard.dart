import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/dashboard/application/dashboard_providers.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/dashboard/presentation/widgets/glass_renewal_list.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Pano — the Liquid-Glass dashboard. A large title over a gold-glow glass hero
/// panel (tiered multi-currency money model) and a glass list of upcoming
/// renewals. Lives inside the shell, so it carries no app bar of its own — the
/// floating nav bar sits above it.
class GlassDashboard extends ConsumerWidget {
  const GlassDashboard({super.key, this.onUpgrade});

  /// Opens the paywall when a free user taps the unified-total teaser.
  final VoidCallback? onUpgrade;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsProvider);
    final topInset = MediaQuery.paddingOf(context).top + 14;

    return subsAsync.when(
      loading: () => const _Centered(child: CircularProgressIndicator(color: AppTokens.accentFg)),
      error: (_, _) => const _Centered(
        child: _GlassMessage(
          icon: Icons.error_outline_rounded,
          title: 'Bir sorun oluştu',
          body: 'Abonelikler yüklenemedi.',
        ),
      ),
      data: (subs) {
        if (subs.isEmpty) {
          return const _Centered(
            child: _GlassMessage(
              icon: Icons.add_circle_outline_rounded,
              title: 'İlk Aboneliğini Ekle',
              body: 'Sağ alttaki + ile abonelik ekleyerek başla.',
            ),
          );
        }

        final now = DateTime.now();
        final items = [for (final s in subs) UpcomingPayment.from(s, now)]
          ..sort((a, b) => a.effectiveRenewal.compareTo(b.effectiveRenewal));
        final monthLabel = '${_months[now.month - 1]} ${now.year}';

        return ListView(
          padding: EdgeInsets.fromLTRB(18, topInset, 18, 128),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text('Abonelikler',
                  style: AppText.largeTitle.copyWith(color: AppTokens.text)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 18),
              child: Text('$monthLabel · ${subs.length} abonelik',
                  style: AppText.subhead.copyWith(color: AppTokens.muted)),
            ),
            _HeroPanel(monthLabel: monthLabel, onUpgrade: onUpgrade),
            const SizedBox(height: 24),
            const _Label('Yaklaşan Ödemeler'),
            const SizedBox(height: 12),
            GlassRenewalCard(payments: items, now: now),
          ],
        );
      },
    );
  }
}

// ── Hero panel ───────────────────────────────────────────────
class _HeroPanel extends ConsumerWidget {
  const _HeroPanel({required this.monthLabel, this.onUpgrade});

  final String monthLabel;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthlySummaryProvider).asData?.value ?? const [];
    if (totals.isEmpty) return const SizedBox.shrink();
    final isPremium = ref.watch(premiumStatusProvider).isPremium;

    return GlassSurface(
      radius: 28,
      fill: GlassFill.strong,
      shadow: AppTokens.glassShadow,
      child: Stack(
        children: [
          // Low-alpha gold glow tying the panel to the premium "money" identity.
          Positioned(
            top: -70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(199, 162, 86, 0.20),
                      Color.fromRGBO(199, 162, 86, 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Label(monthLabel),
                        const GlassPill(text: 'Aylık'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (isPremium)
                      _PremiumTotal(totals: totals)
                    else
                      _FreeTotal(totals: totals),
                  ],
                ),
              ),
              if (!isPremium && totals.length > 1)
                _UnifiedTeaser(onTap: onUpgrade),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumTotal extends ConsumerWidget {
  const _PremiumTotal({required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedDashboardTotalProvider);

    final Widget headline = switch (state) {
      UnifiedReady(:final total) =>
        _BigAmount(amount: formatMoneyTr(total.amount, total.target), prefix: '≈'),
      _ => const _BigAmount(amount: '—', muted: true),
    };

    final caption = switch (state) {
      UnifiedReady(:final fetchedAt) => 'Toplam · Kurlar: ${_fxDate(fetchedAt)}',
      UnifiedUnavailable() => 'Birleşik toplam için kurlar henüz alınamadı',
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headline,
        if (caption != null) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.public, size: 13, color: AppTokens.tertiary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(caption,
                    style: AppText.caption1.copyWith(color: AppTokens.tertiary)),
              ),
            ],
          ),
        ],
        _ChipsRow(totals: totals),
      ],
    );
  }

  static String _fxDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')} güncellendi';
  }
}

class _FreeTotal extends StatelessWidget {
  const _FreeTotal({required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.length == 1) {
      final t = totals.first;
      return _BigAmount(amount: formatMoneyTr(t.monthlyTotal, t.currency));
    }
    return _ChipsRow(totals: totals, primary: true);
  }
}

class _BigAmount extends StatelessWidget {
  const _BigAmount({required this.amount, this.prefix, this.muted = false});

  final String amount;
  final String? prefix;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null) ...[
          Text(prefix!,
              style: const TextStyle(
                  fontSize: 20, color: AppTokens.accentFg, fontWeight: FontWeight.w400)),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.2,
                height: 1,
                color: muted ? AppTokens.muted : AppTokens.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text('/ay', style: TextStyle(fontSize: 17, color: AppTokens.muted)),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.totals, this.primary = false});

  final List<CurrencyTotal> totals;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (var i = 0; i < totals.length; i++) {
      if (i > 0) chips.add(const SizedBox(width: 8));
      chips.add(_chip(totals[i]));
    }
    final row = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: chips),
    );

    if (primary) {
      return Padding(padding: const EdgeInsets.only(top: 2), child: row);
    }
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.only(top: 15),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTokens.hair, width: 0.5)),
      ),
      child: row,
    );
  }

  Widget _chip(CurrencyTotal t) {
    return GlassSurface(
      radius: 999,
      fill: GlassFill.soft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(t.currency.code,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.tertiary,
                  letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Text(formatMoneyTr(t.monthlyTotal, t.currency),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.text)),
        ],
      ),
    );
  }
}

class _UnifiedTeaser extends StatelessWidget {
  const _UnifiedTeaser({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(199, 162, 86, 0.12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color.fromRGBO(199, 162, 86, 0.20), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 17, color: AppTokens.accentFg),
              const SizedBox(width: 11),
              Expanded(
                child: Text('Tek para biriminde toplam · Premium',
                    style: AppText.footnote.copyWith(
                        color: AppTokens.text, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppTokens.accentFg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small shared bits ────────────────────────────────────────
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

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(padding: const EdgeInsets.all(32), child: child),
      );
}

class _GlassMessage extends StatelessWidget {
  const _GlassMessage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 28,
      fill: GlassFill.strong,
      shadow: AppTokens.glassShadow,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppTokens.accentFg),
          const SizedBox(height: 16),
          Text(title, style: AppText.title3.copyWith(color: AppTokens.text)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: AppText.subhead.copyWith(color: AppTokens.muted)),
        ],
      ),
    );
  }
}
