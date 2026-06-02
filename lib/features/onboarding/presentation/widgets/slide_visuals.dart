import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';
import 'package:subsy/shared/widgets/brand_avatar.dart';

/// The four onboarding slide illustrations. Each uses a deliberately different
/// composition (fanned card deck / device + shield / tilted scan / stacked
/// notification + donut) so the hero zone never reads as one static image.
/// All use bundled SVG logos — nothing loads from the network.

const double _visualHeight = 214;

Widget _goldGlow({double size = 220, double opacity = 0.16}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color.fromRGBO(199, 162, 86, opacity),
            const Color.fromRGBO(199, 162, 86, 0),
          ],
        ),
      ),
    );

// ── Slide 1 — Value: a fanned deck of subscription cards ─────────────────────
class ValueVisual extends StatelessWidget {
  const ValueVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _visualHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTokens.panelGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTokens.panelHair, width: 0.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(top: -60, child: _goldGlow(size: 240, opacity: 0.18)),
              // faint total behind the deck
              const Positioned(
                child: Text(
                  '≈ ₺740 /ay',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.4,
                    color: Color.fromRGBO(255, 255, 255, 0.10),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(-10, -10),
                child: Transform.rotate(
                  angle: -0.09,
                  child: _card('netflix', 'Netflix', '₺229,99', dim: true),
                ),
              ),
              Transform.translate(
                offset: const Offset(12, 8),
                child: Transform.rotate(
                  angle: 0.07,
                  child: _card('icloud_plus', 'iCloud+', '₺49,99', dim: true),
                ),
              ),
              _card('spotify', 'Spotify', '₺59,99'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String key, String name, String amount, {bool dim = false}) {
    return Opacity(
      opacity: dim ? 0.65 : 1,
      child: Container(
        width: 236,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTokens.hair2, width: 0.5),
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.35), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            BrandAvatar(serviceKey: key, fallbackName: name, size: 34, circle: true),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTokens.text),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTokens.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide 2 — Privacy: a device with a shield, and a struck-through cloud ────
class PrivacyVisual extends StatelessWidget {
  const PrivacyVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _visualHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: const Alignment(-0.15, 0), child: _goldGlow(size: 180, opacity: 0.14)),
          // phone, nudged left of center
          Align(
            alignment: const Alignment(-0.35, 0),
            child: Container(
              width: 110,
              height: 188,
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTokens.hair2, width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.fromRGBO(199, 162, 86, 0.22), Color.fromRGBO(199, 162, 86, 0.06)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color.fromRGBO(199, 162, 86, 0.3), width: 0.5),
                    ),
                    child: const Icon(Icons.shield_outlined, size: 38, color: AppTokens.accentFg),
                  ),
                  Positioned(
                    bottom: 26,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTokens.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTokens.hair2, width: 1),
                      ),
                      child: const Icon(Icons.lock_outline, size: 16, color: AppTokens.accentFg),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // struck-through "no server" cloud, top-right
          Align(
            alignment: const Alignment(0.7, -0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.cloud_outlined, size: 40, color: AppTokens.tertiary),
                      Transform.rotate(
                        angle: -0.56,
                        child: Container(width: 56, height: 2.5, color: AppTokens.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text('sunucu yok',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTokens.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 3 — OCR: a tilted receipt with a scan beam + a recognized chip ─────
class ScanVisual extends StatelessWidget {
  const ScanVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _visualHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _goldGlow(size: 190, opacity: 0.12),
          // receipt, tilted
          Align(
            alignment: const Alignment(-0.2, -0.1),
            child: Transform.rotate(
              angle: -0.09,
              child: Container(
                width: 130,
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTokens.hair2, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in [0.7, 1.0, 0.55, 0.9, 0.45])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: FractionallySizedBox(
                          widthFactor: w,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppTokens.fillSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    // scan beam
                    Container(
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: AppTokens.accentFg,
                        boxShadow: const [
                          BoxShadow(color: Color.fromRGBO(199, 162, 86, 0.7), blurRadius: 14, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // recognized result chip, sliding in bottom-right
          Align(
            alignment: const Alignment(0.85, 0.7),
            child: Container(
              width: 188,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.sheet,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTokens.hair2, width: 0.5),
                boxShadow: const [
                  BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 26, offset: Offset(0, 12)),
                ],
              ),
              child: Row(
                children: [
                  BrandAvatar(serviceKey: 'spotify', fallbackName: 'Spotify', size: 34, circle: true),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spotify', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTokens.text)),
                        Text('₺59,99', style: TextStyle(fontSize: 12, color: AppTokens.muted)),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppTokens.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 4 — Reminders: a notification banner above a donut ─────────────────
class RemindVisual extends StatelessWidget {
  const RemindVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _visualHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _goldGlow(size: 200, opacity: 0.10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // notification banner
              Container(
                width: 290,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTokens.sheet,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTokens.hair2, width: 0.5),
                  boxShadow: const [
                    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 30, offset: Offset(0, 14)),
                  ],
                ),
                child: Row(
                  children: [
                    BrandAvatar(serviceKey: 'netflix', fallbackName: 'Netflix', size: 40, circle: true),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subsy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTokens.text)),
                              Text('şimdi', style: TextStyle(fontSize: 11, color: AppTokens.tertiary)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('Netflix yarın yenilenecek · ₺229,99',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.text)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // donut
              SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: _DonutPainter(),
                  child: const Center(child: Icon(Icons.pie_chart_outline, size: 22, color: AppTokens.accentFg)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  // Category fractions (sum = 1), matching the stats palette.
  static const _segments = <({double fraction, Color color})>[
    (fraction: 0.34, color: Color(0xFFE5484D)),
    (fraction: 0.26, color: Color(0xFF12A594)),
    (fraction: 0.20, color: Color(0xFF8E4EC6)),
    (fraction: 0.20, color: Color(0xFF3E63DD)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - stroke / 2,
    );
    var start = -math.pi / 2;
    final gap = 0.06;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (final seg in _segments) {
      final sweep = seg.fraction * (2 * math.pi) - gap;
      paint.color = seg.color;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += seg.fraction * (2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => false;
}
