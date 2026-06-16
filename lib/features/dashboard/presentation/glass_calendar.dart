import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/theme/app_text.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/domain/calendar_month.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/dashboard/presentation/widgets/glass_renewal_list.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Takvim — a glass month grid of upcoming renewals. Days with a renewal show
/// the brand logo (+N when several) on a glass cell; tapping a day reveals its
/// renewals below. Current month only (month nav is a later enhancement).
class GlassCalendar extends ConsumerStatefulWidget {
  const GlassCalendar({super.key});

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  ConsumerState<GlassCalendar> createState() => _GlassCalendarState();
}

class _GlassCalendarState extends ConsumerState<GlassCalendar> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final subsAsync = ref.watch(subscriptionsProvider);
    final topInset = MediaQuery.paddingOf(context).top + 14;
    final now = DateTime.now();
    final monthLabel = '${GlassCalendar._months[now.month - 1]} ${now.year}';

    return subsAsync.maybeWhen(
      orElse: () => const Center(
        child: CircularProgressIndicator(color: AppTokens.accentFg),
      ),
      data: (subs) {
        final payments = [for (final s in subs) UpcomingPayment.from(s, now)];
        final month = buildCalendarMonth(payments, now);
        final selected = _selectedDay;

        return ListView(
          padding: EdgeInsets.fromLTRB(18, topInset, 18, 128),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text('Takvim',
                  style: AppText.largeTitle.copyWith(color: AppTokens.text)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 18),
              child: Text(monthLabel,
                  style: AppText.subhead.copyWith(color: AppTokens.muted)),
            ),
            GlassSurface(
              radius: 28,
              fill: GlassFill.strong,
              shadow: AppTokens.glassShadow,
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _weekdayHeader(),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final cell in month.cells)
                        if (cell == null)
                          const SizedBox.shrink()
                        else
                          _DayCell(
                            day: cell,
                            payments: month.paymentsOn(cell),
                            selected: selected == cell,
                            onTap: month.dayHasPayments(cell)
                                ? () => setState(() =>
                                    _selectedDay = selected == cell ? null : cell)
                                : null,
                          ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected != null && month.dayHasPayments(selected)) ...[
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '$selected ${GlassCalendar._months[month.month - 1]}',
                  style: AppText.footnote.copyWith(
                      color: AppTokens.muted, fontWeight: FontWeight.w600),
                ),
              ),
              GlassRenewalCard(payments: month.paymentsOn(selected), now: now),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Center(
                  child: Text('Yenilemeleri görmek için bir güne dokun',
                      style: TextStyle(fontSize: 12.5, color: AppTokens.tertiary)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _weekdayHeader() {
    return Row(
      children: [
        for (final w in GlassCalendar._weekdays)
          Expanded(
            child: Center(
              child: Text(w,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.tertiary,
                      letterSpacing: 0.3)),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.payments,
    required this.selected,
    this.onTap,
  });

  final int day;
  final List<UpcomingPayment> payments;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final has = payments.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: has ? AppTokens.glassFillLens : null,
          color: has ? null : AppTokens.fillFaint,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? AppTokens.accent : AppTokens.hair,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: has ? _withRenewals() : _empty(),
      ),
    );
  }

  Widget _empty() => Center(
        child: Text('$day',
            style: const TextStyle(
                fontSize: 13, color: AppTokens.tertiary, fontWeight: FontWeight.w500)),
      );

  Widget _withRenewals() {
    final first = payments.first.subscription;
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandAvatar(
                serviceKey: first.serviceKey,
                fallbackName: first.name,
                size: 25,
                circle: true,
              ),
              const SizedBox(height: 2),
              Text('$day',
                  style: const TextStyle(
                      fontSize: 9.5, color: AppTokens.muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (payments.length > 1)
          Positioned(
            top: 3,
            right: 4,
            child: Text('+${payments.length - 1}',
                style: const TextStyle(
                    fontSize: 9, color: AppTokens.accentFg, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
