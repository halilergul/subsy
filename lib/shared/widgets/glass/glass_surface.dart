import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// Which translucent fill a [GlassSurface] uses.
///
/// - [soft]   — light white-alpha fill for chips / pills over content.
/// - [strong] — near-opaque dark frost for cards & sheets (reads as glass
///   without a live backdrop blur behind it — the perf-cheap default).
/// - [lens]   — brighter fill for active / elevated elements (selected tab).
enum GlassFill { soft, strong, lens }

/// The core Liquid-Glass material: a translucent gradient [fill] wrapped in a
/// bright 1px specular [glassEdge] rim, optionally over a live backdrop [blur].
///
/// Backdrop blur is a `saveLayer` per surface, so keep [blur] for elements that
/// genuinely float over moving content (tab bar, sheets). Static cards should
/// use the default [GlassFill.strong] with `blur: false`.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    this.radius = 24,
    this.fill = GlassFill.strong,
    this.blur = false,
    this.padding,
    this.shadow,
    this.onTap,
    this.child,
  });

  final double radius;
  final GlassFill fill;
  final bool blur;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Widget? child;

  Gradient get _gradient => switch (fill) {
        GlassFill.soft => AppTokens.glassFill,
        GlassFill.strong => AppTokens.glassFillStrong,
        GlassFill.lens => AppTokens.glassFillLens,
      };

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(gradient: _gradient, borderRadius: br),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (onTap != null) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: br,
                onTap: onTap,
                // A faint glass highlight on press.
                highlightColor: const Color.fromRGBO(255, 255, 255, 0.04),
                splashColor: const Color.fromRGBO(255, 255, 255, 0.06),
              ),
            ),
          ),
        ],
      );
    }

    // Specular edge sits above the fill (and the ink) so the rim never dims.
    Widget surface = CustomPaint(
      foregroundPainter: _SpecularEdgePainter(radius: radius),
      child: content,
    );

    surface = ClipRRect(borderRadius: br, child: surface);

    if (blur) {
      surface = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTokens.glassBlurSigma,
            sigmaY: AppTokens.glassBlurSigma,
          ),
          child: surface,
        ),
      );
    }

    if (shadow != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: br, boxShadow: shadow),
        child: surface,
      );
    }

    return surface;
  }
}

/// Strokes the bright→faint specular rim and a 1px inner top highlight that
/// together give the glass its "lit edge". Drawn inside the surface bounds.
class _SpecularEdgePainter extends CustomPainter {
  _SpecularEdgePainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // Guard against zero/degenerate sizes (mid-layout, collapsing animations):
    // building a gradient shader on an empty rect is undefined and can fault.
    if (size.width <= 2 || size.height <= 2) return;

    final rect = Offset.zero & size;
    final inset = rect.deflate(0.5);
    final r = radius.clamp(0.0, size.shortestSide / 2);
    final rrect = RRect.fromRectAndRadius(inset, Radius.circular(r));

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = AppTokens.glassEdge.createShader(rect);
    canvas.drawRRect(rrect, edge);
  }

  @override
  bool shouldRepaint(covariant _SpecularEdgePainter old) => old.radius != radius;
}
