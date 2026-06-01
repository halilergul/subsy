import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog.dart';
import 'package:subsy/features/subscriptions/domain/brand_catalog_entry.dart';

/// Reusable brand tile. When [serviceKey] resolves in the catalog it shows the
/// bundled SVG logo on the brand color; otherwise a neutral tile with the
/// first letter of [fallbackName]. (The online-fetch fallback is a later
/// feature.) Reused by the dashboard, statistics, and detail screens.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.serviceKey,
    required this.fallbackName,
    this.size = 48,
  });

  final String? serviceKey;
  final String fallbackName;
  final double size;

  static const Color _fallbackColor = Color(0xFF2A2A33);

  @override
  Widget build(BuildContext context) {
    final BrandCatalogEntry? entry = brandByKey(serviceKey);
    final radius = size * 0.28;

    if (entry != null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.18),
        decoration: BoxDecoration(
          color: Color(entry.brandColor),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SvgPicture.asset(
          entry.logoAsset,
          fit: BoxFit.contain,
        ),
      );
    }

    final initial = _initialOf(fallbackName);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _fallbackColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}
