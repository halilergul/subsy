import 'package:flutter/painting.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';

/// Stable, distinct display color per category (research.md D7). Shared between
/// the statistics donut segment and its legend row so they always match
/// (FR-003). Reusable by future detail/insight screens.
Color categoryColor(SubscriptionCategory c) => switch (c) {
      SubscriptionCategory.streaming => const Color(0xFFE5484D),
      SubscriptionCategory.music => const Color(0xFF30A46C),
      SubscriptionCategory.cloud => const Color(0xFF3E63DD),
      SubscriptionCategory.ai => const Color(0xFF12A594),
      SubscriptionCategory.productivity => const Color(0xFF8E4EC6),
      SubscriptionCategory.shopping => const Color(0xFFF76808),
      SubscriptionCategory.other => const Color(0xFF7E808A),
    };

/// Turkish display label per category.
String categoryLabel(SubscriptionCategory c) => switch (c) {
      SubscriptionCategory.streaming => 'Yayın',
      SubscriptionCategory.music => 'Müzik',
      SubscriptionCategory.cloud => 'Bulut',
      SubscriptionCategory.ai => 'Yapay zeka',
      SubscriptionCategory.productivity => 'Üretkenlik',
      SubscriptionCategory.shopping => 'Alışveriş',
      SubscriptionCategory.other => 'Diğer',
    };
