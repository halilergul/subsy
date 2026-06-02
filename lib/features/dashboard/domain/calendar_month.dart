import 'package:subsy/features/dashboard/domain/upcoming_payment.dart';

/// A month laid out for the calendar grid: Monday-first cells (null = padding
/// before the 1st) plus renewals grouped by day-of-month.
///
/// Only renewals whose effective date lands in [year]/[month] are grouped;
/// each subscription contributes its single next renewal (FR — the dashboard
/// shows upcoming, not a full recurring projection).
class CalendarMonth {
  CalendarMonth({
    required this.year,
    required this.month,
    required this.cells,
    required this.paymentsByDay,
  });

  final int year;
  final int month;

  /// Grid cells, Monday-first. `null` entries are leading blanks before day 1.
  final List<int?> cells;

  /// day-of-month → renewals on that day, sorted by name.
  final Map<int, List<UpcomingPayment>> paymentsByDay;

  bool dayHasPayments(int day) => paymentsByDay[day]?.isNotEmpty ?? false;

  List<UpcomingPayment> paymentsOn(int day) => paymentsByDay[day] ?? const [];
}

/// Builds the [CalendarMonth] for the month containing [reference] from the
/// given upcoming [payments].
CalendarMonth buildCalendarMonth(
  List<UpcomingPayment> payments,
  DateTime reference,
) {
  final year = reference.year;
  final month = reference.month;

  // Monday-first index of the 1st (Dart: Mon=1..Sun=7 → 0..6).
  final firstWeekday = DateTime(year, month, 1).weekday;
  final leadingBlanks = firstWeekday - 1;
  final daysInMonth = DateTime(year, month + 1, 0).day;

  final cells = <int?>[
    for (var i = 0; i < leadingBlanks; i++) null,
    for (var d = 1; d <= daysInMonth; d++) d,
  ];

  final byDay = <int, List<UpcomingPayment>>{};
  for (final p in payments) {
    final r = p.effectiveRenewal;
    if (r.year == year && r.month == month) {
      (byDay[r.day] ??= <UpcomingPayment>[]).add(p);
    }
  }
  for (final list in byDay.values) {
    list.sort((a, b) =>
        a.subscription.name.toLowerCase().compareTo(b.subscription.name.toLowerCase()));
  }

  return CalendarMonth(
    year: year,
    month: month,
    cells: cells,
    paymentsByDay: byDay,
  );
}
