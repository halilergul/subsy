import 'package:flutter/material.dart';
import 'package:subsy/features/subscriptions/domain/brand_resolver.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// Live brand preview: resolves the typed service name to a catalog entry and
/// shows its logo/color (or a neutral initial for unknown names).
class BrandPreview extends StatelessWidget {
  const BrandPreview({super.key, required this.name, this.resolver = const BrandResolver()});

  final String name;
  final BrandResolver resolver;

  @override
  Widget build(BuildContext context) {
    final entry = name.trim().isEmpty ? null : resolver.resolve(name);
    return Center(
      child: BrandAvatar(
        serviceKey: entry?.serviceKey,
        fallbackName: name.trim().isEmpty ? '?' : name,
        size: 64,
      ),
    );
  }
}
