import 'package:flutter/material.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Constrained billing-period picker with Turkish labels.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.value, required this.onChanged});

  final BillingPeriod value;
  final ValueChanged<BillingPeriod> onChanged;

  static const Map<BillingPeriod, String> _labels = {
    BillingPeriod.weekly: 'Haftalık',
    BillingPeriod.monthly: 'Aylık',
    BillingPeriod.yearly: 'Yıllık',
  };

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<BillingPeriod>(
      segments: [
        for (final p in BillingPeriod.values)
          ButtonSegment(value: p, label: Text(_labels[p]!)),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
