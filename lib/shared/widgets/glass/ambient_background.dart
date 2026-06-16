import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// The slowly-drifting colour field the glass refracts: a handful of large,
/// soft radial blobs (gold · violet · teal · red) over the app background.
///
/// Cheap by design — the blobs are pure radial gradients (no per-frame
/// `ImageFilter.blur`), wrapped in a [RepaintBoundary]. Honours the platform
/// "reduce motion" setting by freezing the drift.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  static const _blobs = <_Blob>[
    _Blob(color: AppTokens.accent, alpha: 0.26, size: 360, x: -0.7, y: -0.85, phase: 0.0, amp: 0.10),
    _Blob(color: AppTokens.ambientViolet, alpha: 0.24, size: 320, x: 0.85, y: -0.25, phase: 0.3, amp: 0.12),
    _Blob(color: AppTokens.ambientTeal, alpha: 0.18, size: 300, x: -0.8, y: 0.7, phase: 0.6, amp: 0.11),
    _Blob(color: AppTokens.ambientRed, alpha: 0.14, size: 220, x: 0.7, y: -0.6, phase: 0.85, amp: 0.09),
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 64));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Drive the drift only when motion is allowed. Freezing it when reduce-motion
    // is on also lets `pumpAndSettle` settle in widget tests (an endless repeat
    // would otherwise hang them).
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return RepaintBoundary(
      child: ColoredBox(
        color: AppTokens.bg,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = reduceMotion ? 0.0 : _c.value;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      for (final b in _blobs) _positioned(b, t, w, h),
                      // Depth vignette toward the bottom.
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.2,
                              colors: [
                                Color.fromRGBO(0, 0, 0, 0),
                                Color.fromRGBO(0, 0, 0, 0.4),
                              ],
                              stops: [0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _positioned(_Blob b, double t, double w, double h) {
    final angle = 2 * math.pi * (t + b.phase);
    final dx = math.sin(angle) * b.amp * w;
    final dy = math.cos(angle * 0.8) * b.amp * h;
    // Map normalised (-1..1) anchor to a centre offset, then add drift.
    final cx = (b.x + 1) / 2 * w + dx;
    final cy = (b.y + 1) / 2 * h + dy;
    return Positioned(
      left: cx - b.size / 2,
      top: cy - b.size / 2,
      width: b.size,
      height: b.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              b.color.withValues(alpha: b.alpha),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.72],
          ),
        ),
      ),
    );
  }
}

class _Blob {
  const _Blob({
    required this.color,
    required this.alpha,
    required this.size,
    required this.x,
    required this.y,
    required this.phase,
    required this.amp,
  });

  final Color color;
  final double alpha;
  final double size;
  final double x; // normalised anchor -1..1
  final double y;
  final double phase; // 0..1 drift offset
  final double amp; // drift amplitude (fraction of axis)
}
