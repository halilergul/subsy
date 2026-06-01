import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';

/// Resolves a free-text service name to a [BrandCatalogEntry]. Matching is
/// case-insensitive, Turkish-character tolerant, and alias-aware (FR-012).
/// Returns null for unknown names — never throws (FR-013).
class BrandResolver {
  const BrandResolver([this.catalog = kBrandCatalog]);

  final List<BrandCatalogEntry> catalog;

  BrandCatalogEntry? resolve(String serviceName) {
    final query = _normalize(serviceName);
    if (query.isEmpty) return null;

    for (final entry in catalog) {
      if (_normalize(entry.displayName) == query) return entry;
      for (final alias in entry.aliases) {
        if (_normalize(alias) == query) return entry;
      }
    }
    return null;
  }

  /// Folds Turkish characters to ASCII, lowercases, and collapses whitespace
  /// so "İcloud", "BLUTV", "Exxen" all normalize predictably. Dart's default
  /// `toLowerCase()` mishandles the Turkish dotted/dotless I, hence the
  /// explicit fold first.
  static String _normalize(String input) {
    const folds = {
      'İ': 'i', 'I': 'i', 'ı': 'i',
      'Ş': 's', 'ş': 's',
      'Ğ': 'g', 'ğ': 'g',
      'Ç': 'c', 'ç': 'c',
      'Ö': 'o', 'ö': 'o',
      'Ü': 'u', 'ü': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in input.trim().runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(folds[ch] ?? ch);
    }
    return buffer
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
