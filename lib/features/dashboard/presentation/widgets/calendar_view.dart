import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/features/dashboard/domain/calendar_month.dart';
import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';
import 'package:subsy/features/dashboard/presentation/widgets/dashboard_chrome.dart';
import 'package:subsy/features/dashboard/presentation/widgets/sub_row.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// Month calendar of upcoming renewals. Days with a renewal show the brand
/// logo (+N when several); tapping a day reveals its renewals below the grid.
class CalendarView extends StatefulWidget {
  const CalendarView({
    super.key,
    required this.payments,
    required this.now,
    this.onOpenSub,
  });

  final List<UpcomingPayment> payments;
  final DateTime now;
  final void Function(UpcomingPayment payment)? onOpenSub;

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final month = buildCalendarMonth(widget.payments, widget.now);
    final selected = _selectedDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _weekdayHeader(),
        const SizedBox(height: 6),
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
                      ? () => setState(
                          () => _selectedDay = selected == cell ? null : cell)
                      : null,
                ),
          ],
        ),
        if (selected != null && month.dayHasPayments(selected)) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel(
              '$selected ${CalendarView._months[month.month - 1]}',
            ),
          ),
          SubscriptionListCard(
            payments: month.paymentsOn(selected),
            now: widget.now,
            onTap: widget.onOpenSub,
          ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Yenilemeleri görmek için bir güne dokun',
                style: TextStyle(fontSize: 12.5, color: AppTokens.tertiary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _weekdayHeader() {
    return Row(
      children: [
        for (final w in CalendarView._weekdays)
          Expanded(
            child: Center(
              child: Text(
                w,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.tertiary,
                  letterSpacing: 0.3,
                ),
              ),
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
      child: Container(
        decoration: BoxDecoration(
          color: has ? AppTokens.surface : AppTokens.fillFaint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTokens.accent : AppTokens.hair,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: has ? _withRenewals(context) : _empty(),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Text(
        '$day',
        style: const TextStyle(fontSize: 13, color: AppTokens.tertiary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _withRenewals(BuildContext context) {
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
                size: 26,
                circle: true,
              ),
              const SizedBox(height: 2),
              Text(
                '$day',
                style: const TextStyle(fontSize: 9.5, color: AppTokens.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (payments.length > 1)
          Positioned(
            top: 4,
            right: 5,
            child: Text(
              '+${payments.length - 1}',
              style: const TextStyle(fontSize: 9, color: AppTokens.accentFg, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
