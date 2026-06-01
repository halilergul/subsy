import 'package:subsy/features/subscriptions/domain/enums.dart';

/// A known service's branding, bundled with the app (offline, FR-010).
/// Read-only reference data — not persisted in Isar.
class BrandCatalogEntry {
  const BrandCatalogEntry({
    required this.serviceKey,
    required this.displayName,
    required this.brandColor,
    required this.logoAsset,
    required this.defaultCategory,
    this.aliases = const [],
  });

  /// Stable key, e.g. "netflix", "youtube_premium".
  final String serviceKey;

  /// Canonical display name, e.g. "Netflix".
  final String displayName;

  /// Brand color as an ARGB int, e.g. 0xFFE50914.
  final int brandColor;

  /// Bundled SVG path, e.g. "assets/logos/netflix.svg".
  final String logoAsset;

  final SubscriptionCategory defaultCategory;

  /// Extra matchable names (lowercased/normalized at resolve time).
  final List<String> aliases;
}
