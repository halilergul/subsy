import 'package:subsy/features/subscription_import/domain/recognized_draft.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Pure: flags a recognized draft that likely duplicates an existing
/// subscription (FR-014). A match is the same brand key, or the same
/// normalized name. Returns the existing subscription's display name, or null.
class DuplicateDetector {
  const DuplicateDetector();

  String? findDuplicate(RecognizedDraft draft, List<Subscription> existing) {
    final draftName = BrandResolver.normalize(draft.name);
    for (final s in existing) {
      final sameBrand = draft.serviceKey != null && draft.serviceKey == s.serviceKey;
      final sameName = draftName.isNotEmpty &&
          draftName == BrandResolver.normalize(s.name);
      if (sameBrand || sameName) return s.name;
    }
    return null;
  }
}
