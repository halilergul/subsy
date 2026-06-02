import 'package:flutter/material.dart';

/// Central design tokens, mirrored from the Claude Design handoff
/// (`tokens.jsx` — DARK palette + gold accent). Dark mode is the primary,
/// mandatory theme (CONSTITUTION.md). Light mode is deferred; when added, these
/// become theme-resolved instead of const.
///
/// Keep this in sync with the design bundle: the gold accent and the hero-panel
/// gradient are the visual signature of the app.
abstract final class AppTokens {
  const AppTokens._();

  // ── Surfaces ───────────────────────────────────────────────
  static const Color bg = Color(0xFF0E0E12); // app background
  static const Color surface = Color(0xFF17171D); // elevated card
  static const Color surface2 = Color(0xFF202028); // secondary surface
  static const Color sheet = Color(0xFF16161B); // modal bottom-sheet

  // ── Hairlines / fills ──────────────────────────────────────
  static const Color hair = Color.fromRGBO(255, 255, 255, 0.07);
  static const Color hair2 = Color.fromRGBO(255, 255, 255, 0.12);
  static const Color fill = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color fillSoft = Color.fromRGBO(255, 255, 255, 0.05);
  static const Color fillFaint = Color.fromRGBO(255, 255, 255, 0.02);

  // ── Text ───────────────────────────────────────────────────
  static const Color text = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF9A9AA2);
  static const Color tertiary = Color(0xFF6E6E78);

  // ── Status ─────────────────────────────────────────────────
  static const Color green = Color(0xFF30D158);
  static const Color amber = Color(0xFFFF9500); // warning — orange, NOT gold
  static const Color amberText = Color(0xFFFF9F45);
  static const Color red = Color(0xFFE5484D);

  // ── Accent (gold — theme-invariant gradient) ───────────────
  static const Color accent = Color(0xFFC7A256);
  static const Color accentSoft = Color(0xFFE6C97E);
  static const Color accentFg = Color(0xFFE6C97E); // on-surface foreground gold
  static const Color onAccent = Color(0xFF1A1405); // glyph/text on gold fill

  // ── Hero summary panel ─────────────────────────────────────
  static const Color panelA = Color(0xFF1C1C22);
  static const Color panelB = Color(0xFF161619);
  static const Color panelHair = Color.fromRGBO(255, 255, 255, 0.10);

  // ── Sheet chrome ───────────────────────────────────────────
  static const Color scrim = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color grabber = Color.fromRGBO(255, 255, 255, 0.2);

  // ── Derived gradients ──────────────────────────────────────
  /// Hero panel vertical gradient (panelA → panelB).
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [panelA, panelB],
  );

  /// Gold CTA / FAB gradient (accentSoft → accent), 160° in the design.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentSoft, accent],
  );

  /// Soft shadow for the active segment in the view toggle.
  static const List<BoxShadow> segShadow = [
    BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Glow cast behind the gold FAB.
  static List<BoxShadow> get fabShadow => const [
        BoxShadow(color: Color.fromRGBO(199, 162, 86, 0.4), blurRadius: 24, offset: Offset(0, 8)),
      ];
}
