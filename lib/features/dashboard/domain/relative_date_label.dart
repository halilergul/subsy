import 'package:intl/intl.dart';
import 'package:subsy/shared/constants/dashboard_constants.dart';

/// Human-friendly Turkish label for how soon [renewal] is, relative to [now]:
/// "Bugün" / "Yarın" / "N gün sonra" / an absolute date past the threshold.
/// Locale-independent numeric date (dd.MM.yyyy) so it needs no locale init.
String relativeDateLabel(DateTime renewal, DateTime now) {
  final diff = _dateOnly(renewal).difference(_dateOnly(now)).inDays;
  if (diff <= 0) return 'Bugün';
  if (diff == 1) return 'Yarın';
  if (diff <= kRelativeDayThreshold) return '$diff gün sonra';
  return DateFormat('dd.MM.yyyy').format(renewal);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
