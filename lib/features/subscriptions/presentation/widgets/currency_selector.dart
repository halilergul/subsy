import 'package:flutter/material.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Constrained currency picker (only TRY/USD/EUR selectable).
class CurrencySelector extends StatelessWidget {
  const CurrencySelector({super.key, required this.value, required this.onChanged});

  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Currency>(
      segments: [
        for (final c in Currency.values)
          ButtonSegment(value: c, label: Text(c.code)),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
