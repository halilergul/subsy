import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';

/// A catalog brand found within free OCR text, with its position in the
/// normalized text (used to anchor multi-subscription segmentation).
class BrandMatch {
  const BrandMatch(this.serviceKey, this.displayName, this.start);
  final String serviceKey;
  final String displayName;
  final int start;
}

/// Pure: finds catalog brands inside free text (research.md D4). Uses the same
/// Turkish-tolerant normalization as [BrandResolver] so in-text scanning and
/// exact form matching agree. Longest/alias-aware match wins; overlapping
/// shorter matches are dropped. Never throws; returns `[]` for no matches.
class BrandTextMatcher {
  const BrandTextMatcher([this.catalog = kBrandCatalog]);

  final List<BrandCatalogEntry> catalog;

  List<BrandMatch> findIn(String text) {
    final haystack = BrandResolver.normalize(text);
    if (haystack.isEmpty) return const [];

    // Candidate (entry, needle) pairs, longest needle first so "youtube music"
    // beats a bare "youtube" and we don't double-anchor.
    final candidates = <({BrandCatalogEntry entry, String needle})>[];
    for (final entry in catalog) {
      candidates.add((entry: entry, needle: BrandResolver.normalize(entry.displayName)));
      for (final alias in entry.aliases) {
        candidates.add((entry: entry, needle: BrandResolver.normalize(alias)));
      }
    }
    candidates.sort((a, b) => b.needle.length.compareTo(a.needle.length));

    final matches = <BrandMatch>[];
    final takenRanges = <({int start, int end})>[];
    final seenKeys = <String>{};

    for (final c in candidates) {
      if (c.needle.isEmpty || seenKeys.contains(c.entry.serviceKey)) continue;
      final idx = _wordIndexOf(haystack, c.needle);
      if (idx < 0) continue;
      final end = idx + c.needle.length;
      final overlaps = takenRanges.any((r) => idx < r.end && end > r.start);
      if (overlaps) continue;
      matches.add(BrandMatch(c.entry.serviceKey, c.entry.displayName, idx));
      takenRanges.add((start: idx, end: end));
      seenKeys.add(c.entry.serviceKey);
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }

  /// Substring search that requires word boundaries so "hbo" doesn't match
  /// inside another word. Returns the index, or -1.
  int _wordIndexOf(String haystack, String needle) {
    var from = 0;
    while (true) {
      final idx = haystack.indexOf(needle, from);
      if (idx < 0) return -1;
      final beforeOk = idx == 0 || !_isWordChar(haystack[idx - 1]);
      final afterIdx = idx + needle.length;
      final afterOk =
          afterIdx >= haystack.length || !_isWordChar(haystack[afterIdx]);
      if (beforeOk && afterOk) return idx;
      from = idx + 1;
    }
  }

  bool _isWordChar(String ch) => RegExp(r'[a-z0-9]').hasMatch(ch);
}
