import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/domain/unified_total.dart';
import 'package:subsy/features/dashboard/application/dashboard_providers.dart';
import 'package:subsy/features/dashboard/domain/currency_summary.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_chrome.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Hero summary panel — the differentiated card pinned above the view toggle.
/// Gradient panel + gold glow with a tiered money model:
///  • Premium → big unified "≈ total /ay" + per-currency chips + FX note.
///  • Free, single currency → that currency's real monthly total (no upsell —
///    it already IS their total).
///  • Free, multi-currency → per-currency chips as the hero + a locked
///    "unified total" teaser (we never blur their real per-currency numbers).
class SummaryPanel extends ConsumerWidget {
  const SummaryPanel({super.key, this.onUpgrade});

  /// Opens the paywall when the free user taps the unified-total teaser.
  final VoidCallback? onUpgrade;

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthlySummaryProvider).asData?.value ?? const [];
    if (totals.isEmpty) return const SizedBox.shrink();

    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final now = DateTime.now();
    final monthLabel = '${_months[now.month - 1]} ${now.year}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTokens.panelGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTokens.panelHair, width: 0.5),
        ),
        child: Stack(
          children: [
            // Low-alpha gold radial glow behind the total.
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
                        Color.fromRGBO(199, 162, 86, 0.18),
                        Color.fromRGBO(199, 162, 86, 0.0),
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
                      _header(monthLabel),
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
      ),
    );
  }

  Widget _header(String monthLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SectionLabel(monthLabel),
        const PeriodPill(period: BillingPeriod.monthly),
      ],
    );
  }
}

/// Premium hero: big unified "≈ total /ay" + chips + FX freshness note.
class _PremiumTotal extends ConsumerWidget {
  const _PremiumTotal({required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unifiedDashboardTotalProvider);

    final Widget headline = switch (state) {
      UnifiedReady(:final total) => _BigAmount(
          amount: formatMoneyTr(total.amount, total.target),
          prefix: '≈',
        ),
      UnifiedUnavailable() || UnifiedLocked() || UnifiedLoading() =>
        const _BigAmountUnavailable(),
    };

    final caption = switch (state) {
      UnifiedReady(:final fetchedAt) =>
        'Toplam · Kurlar: ${_fxDate(fetchedAt)}',
      UnifiedUnavailable() =>
        'Birleşik toplam için kurlar henüz alınamadı',
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
                child: Text(
                  caption,
                  style: const TextStyle(fontSize: 12.5, color: AppTokens.tertiary),
                ),
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

/// Free hero: single-currency → real total; multi-currency → chips are the hero.
class _FreeTotal extends StatelessWidget {
  const _FreeTotal({required this.totals});

  final List<CurrencyTotal> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.length == 1) {
      final t = totals.first;
      return _BigAmount(amount: formatMoneyTr(t.monthlyTotal, t.currency));
    }
    // Multi-currency free: per-currency chips ARE the primary content.
    return _ChipsRow(totals: totals, primary: true);
  }
}

/// Big money figure with optional "≈" prefix and a "/ay" suffix.
class _BigAmount extends StatelessWidget {
  const _BigAmount({required this.amount, this.prefix});

  final String amount;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null) ...[
          Text(
            prefix!,
            style: const TextStyle(fontSize: 20, color: AppTokens.accentFg, fontWeight: FontWeight.w400),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w300,
                letterSpacing: -1.6,
                color: AppTokens.text,
                height: 1,
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

class _BigAmountUnavailable extends StatelessWidget {
  const _BigAmountUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '— /ay',
      style: TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.6,
        color: AppTokens.muted,
        height: 1,
      ),
    );
  }
}

/// Per-currency chips on a single row. Shrinks uniformly (never wraps) when the
/// three amounts are too wide for the panel. When [primary] the row carries a
/// little more top spacing since it stands in for the big number.
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

    if (primary) return Padding(padding: const EdgeInsets.only(top: 2), child: row);

    // Secondary chips sit under a hairline divider beneath the big number.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.fillSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppTokens.hair, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            t.currency.code,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTokens.tertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatMoneyTr(t.monthlyTotal, t.currency),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.text),
          ),
        ],
      ),
    );
  }
}

/// Free-user upsell strip: "Tek para biriminde toplam · Premium".
class _UnifiedTeaser extends StatelessWidget {
  const _UnifiedTeaser({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(199, 162, 86, 0.10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color.fromRGBO(199, 162, 86, 0.16), width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(199, 162, 86, 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.lock_outline, size: 16, color: AppTokens.accentFg),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tek para biriminde toplam',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.text),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '≈ kur çevirisi · Premium',
                      style: TextStyle(fontSize: 12, color: AppTokens.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppTokens.accentFg),
            ],
          ),
        ),
      ),
    );
  }
}
