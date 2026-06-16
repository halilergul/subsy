import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/glass/glass_surface.dart';

/// Circular glass icon button — the universal back / close / action affordance.
///
/// The visible chip is [size]; the tappable area is always ≥44pt (iOS HIG).
/// [active] swaps to the brighter lens fill.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.color,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final hit = size < 44 ? 44.0 : size;
    return SizedBox(
      width: hit,
      height: hit,
      child: Center(
        child: GlassSurface(
          radius: size / 2,
          fill: active ? GlassFill.lens : GlassFill.soft,
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.46,
              color: color ?? (active ? AppTokens.accentFg : AppTokens.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold primary CTA — a glass-gold pill (accentSoft→accent gradient, dark
/// glyph, soft gold glow). Falls back to a muted glass fill when [enabled] is
/// false.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _shell(
        gradient: null,
        color: AppTokens.fill,
        fg: AppTokens.tertiary,
        shadow: null,
        onTap: null,
      );
    }
    return _shell(
      gradient: AppTokens.accentGradient,
      color: null,
      fg: AppTokens.onAccent,
      shadow: const [
        BoxShadow(
          color: Color.fromRGBO(199, 162, 86, 0.4),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ],
      onTap: onTap,
    );
  }

  Widget _shell({
    required Gradient? gradient,
    required Color? color,
    required Color fg,
    required List<BoxShadow>? shadow,
    required VoidCallback? onTap,
  }) {
    final br = BorderRadius.circular(999);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: shadow),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: br,
          ),
          child: InkWell(
            borderRadius: br,
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 9),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
