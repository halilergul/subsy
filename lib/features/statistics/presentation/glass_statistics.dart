import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/statistics/application/statistics_providers.dart';
import 'package:subsy/features/statistics/domain/category_breakdown.dart';
import 'package:subsy/features/statistics/domain/ranked_subscription.dart';
import 'package:subsy/features/statistics/domain/stat_period.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/shared/constants/category_style.dart';
import 'package:subsy/shared/utils/money_format.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_segmented.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Özet — Liquid-Glass statistics. A period toggle over per-currency glass
/// donut + legend cards and an "En Pahalı" list. Multi-currency is never
/// blended: each currency gets its own section (TRY→USD→EUR).
class GlassStatistics extends ConsumerWidget {
  const GlassStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final period = ref.watch(statPeriodProvider);
    final topInset = MediaQuery.paddingOf(context).top + 14;

    return stats.maybeWhen(
      orElse: () => const Center(
        child: CircularProgressIndicator(color: AppTokens.accentFg),
      ),
      data: (view) {
        return ListView(
          padding: EdgeInsets.fromLTRB(18, topInset, 18, 128),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text('İstatistik',
                  style: AppText.largeTitle.copyWith(color: AppTokens.text)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 18),
              child: Text('Kategori dağılımı',
                  style: AppText.subhead.copyWith(color: AppTokens.muted)),
            ),
            Center(
              child: SizedBox(
                width: 240,
                child: GlassSegmented<StatPeriod>(
                  value: period,
                  segments: const [
                    GlassSegment(StatPeriod.monthly, 'Aylık'),
                    GlassSegment(StatPeriod.yearly, 'Yıllık'),
                  ],
                  onChanged: (v) =>
                      ref.read(statPeriodProvider.notifier).state = v,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (view.isEmpty)
              const _GlassEmpty()
            else
              for (final b in view.breakdowns) ...[
                if (view.breakdowns.length > 1) _CurrencyHeader(currency: b.currency),
                _BreakdownCard(breakdown: b),
                const SizedBox(height: 14),
                if ((view.topByCurrency[b.currency] ?? const []).isNotEmpty) ...[
                  const _Label('En Pahalı'),
                  const SizedBox(height: 12),
                  _TopList(items: view.topByCurrency[b.currency]!, currency: b.currency),
                  const SizedBox(height: 22),
                ],
              ],
          ],
        );
      },
    );
  }
}

class _CurrencyHeader extends StatelessWidget {
  const _CurrencyHeader({required this.currency});
  final Currency currency;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text('${currency.code} ${currencySymbol(currency)}',
            style: AppText.footnote.copyWith(
                color: AppTokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});
  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final top = breakdown.slices.first;
    return GlassSurface(
      radius: 28,
      fill: GlassFill.strong,
      shadow: AppTokens.glassShadow,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(210, 210),
                  painter: _DonutPainter(breakdown.slices),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: categoryColor(top.category),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(categoryLabel(top.category),
                            style: AppText.subhead.copyWith(
                                color: AppTokens.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(formatMoneyTr(top.amount, breakdown.currency, decimals: 0),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                            color: AppTokens.text)),
                    const SizedBox(height: 2),
                    Text('%${top.percentage.round()} · en yüksek',
                        style: AppText.caption1.copyWith(color: AppTokens.tertiary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < breakdown.slices.length; i++)
            _legendRow(breakdown.slices[i], breakdown.currency, i > 0),
        ],
      ),
    );
  }

  Widget _legendRow(CategorySlice s, Currency currency, bool divider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: AppTokens.hair, width: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.5),
              color: categoryColor(s.category),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(categoryLabel(s.category),
                style: const TextStyle(fontSize: 14.5, color: AppTokens.text)),
          ),
          Text(formatMoneyTr(s.amount, currency, decimals: 0),
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTokens.text)),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text('%${s.percentage.round()}',
                textAlign: TextAlign.right,
                style: AppText.caption1.copyWith(color: AppTokens.tertiary)),
          ),
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList({required this.items, required this.currency});
  final List<RankedSubscription> items;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 24,
      fill: GlassFill.strong,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              decoration: BoxDecoration(
                border: i > 0
                    ? const Border(top: BorderSide(color: AppTokens.hair, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.tertiary)),
                  ),
                  const SizedBox(width: 8),
                  BrandAvatar(
                    serviceKey: items[i].subscription.serviceKey,
                    fallbackName: items[i].subscription.name,
                    size: 38,
                    circle: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(items[i].subscription.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.text)),
                  ),
                  Text(formatMoneyTr(items[i].amount, currency, decimals: 0),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.text)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices);
  final List<CategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 4) return;
    final stroke = size.width * 0.17;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gap = slices.length > 1 ? 0.05 : 0.0; // radians between slices

    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.percentage / 100 * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = categoryColor(s.category);
      canvas.drawArc(rect, start + gap / 2, math.max(0.0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.slices != slices;
}

class _GlassEmpty extends StatelessWidget {
  const _GlassEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: GlassSurface(
        radius: 28,
        fill: GlassFill.strong,
        shadow: AppTokens.glassShadow,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.donut_large_rounded, size: 40, color: AppTokens.accentFg),
            const SizedBox(height: 16),
            Text('Görüntülenecek Veri Yok',
                style: AppText.title3.copyWith(color: AppTokens.text)),
            const SizedBox(height: 6),
            Text('Abonelik ekledikçe harcama dağılımın burada görünecek.',
                textAlign: TextAlign.center,
                style: AppText.subhead.copyWith(color: AppTokens.muted)),
          ],
        ),
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
