import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/dashboard/domain/relative_date_label.dart';

/// US1 — Turkish relative-time label.
void main() {
  final now = DateTime(2026, 6, 1);

  test('today → Bugün', () {
    expect(relativeDateLabel(DateTime(2026, 6, 1), now), 'Bugün');
  });

  test('tomorrow → Yarın', () {
    expect(relativeDateLabel(DateTime(2026, 6, 2), now), 'Yarın');
  });

  test('a few days → N gün sonra', () {
    expect(relativeDateLabel(DateTime(2026, 6, 6), now), '5 gün sonra');
  });

  test('exactly at threshold (30) → N gün sonra', () {
    expect(relativeDateLabel(DateTime(2026, 7, 1), now), '30 gün sonra');
  });

  test('beyond threshold → absolute date dd.MM.yyyy', () {
    expect(relativeDateLabel(DateTime(2026, 7, 2), now), '02.07.2026');
  });
}
