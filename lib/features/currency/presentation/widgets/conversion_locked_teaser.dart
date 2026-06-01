import 'package:flutter/material.dart';

/// Premium upsell shown in place of the unified total for free users. Never
/// shows a real converted number (FR-014/015).
class ConversionLockedTeaser extends StatelessWidget {
  const ConversionLockedTeaser({super.key, this.onUpgrade});

  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Premium ile tüm aboneliklerini tek para biriminde gör',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (onUpgrade != null)
          TextButton(onPressed: onUpgrade, child: const Text('Premium')),
      ],
    );
  }
}
