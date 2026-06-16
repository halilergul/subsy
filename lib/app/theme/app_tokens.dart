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

  // ── Liquid Glass material (iOS 26) ─────────────────────────
  // Mirrors `glass.jsx` GLASS.dark. The glass surfaces layer a translucent
  // gradient FILL inside a bright specular EDGE; live backdrop blur is reserved
  // for surfaces that float over moving content (tab bar, sheets) for perf —
  // static cards use the (near-opaque) strong fill alone.

  /// Blur sigma for live backdrop-filtered glass (tab bar / sheets).
  static const double glassBlurSigma = 22;

  /// Light translucent fill for chips / lens elements over content.
  static const LinearGradient glassFill = LinearGradient(
    begin: Alignment(0.25, -1),
    end: Alignment(-0.25, 1),
    colors: [Color.fromRGBO(255, 255, 255, 0.10), Color.fromRGBO(255, 255, 255, 0.045)],
  );

  /// Near-opaque dark fill for cards / sheets — reads as frosted glass without
  /// a live BackdropFilter behind it.
  static const LinearGradient glassFillStrong = LinearGradient(
    begin: Alignment(0.1, -1),
    end: Alignment(-0.1, 1),
    colors: [Color.fromRGBO(36, 36, 48, 0.66), Color.fromRGBO(16, 16, 24, 0.74)],
  );

  /// Brighter lens fill for active/elevated elements (selected tab, segment).
  static const LinearGradient glassFillLens = LinearGradient(
    begin: Alignment(0.25, -1),
    end: Alignment(-0.25, 1),
    colors: [Color.fromRGBO(255, 255, 255, 0.16), Color.fromRGBO(255, 255, 255, 0.07)],
  );

  /// Specular edge — the bright-to-faint gradient painted as a 1px rim around
  /// every glass surface. This is the signature "lit glass" highlight.
  static const LinearGradient glassEdge = LinearGradient(
    begin: Alignment(0.2, -1),
    end: Alignment(-0.2, 1),
    colors: [
      Color.fromRGBO(255, 255, 255, 0.35),
      Color.fromRGBO(255, 255, 255, 0.08),
      Color.fromRGBO(255, 255, 255, 0.04),
      Color.fromRGBO(255, 255, 255, 0.18),
    ],
    stops: [0.0, 0.38, 0.62, 1.0],
  );

  /// Inner top highlight alpha (simulates CSS `inset 0 1px 0`).
  static const Color glassInnerHighlight = Color.fromRGBO(255, 255, 255, 0.16);

  /// Drop shadow under floating glass (tab bar, FAB, sheets).
  static List<BoxShadow> get glassShadow => const [
        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.45), blurRadius: 40, offset: Offset(0, 16)),
      ];

  /// Stronger scrim behind modal sheets (rgba(4,4,9,0.52)).
  static const Color scrimStrong = Color.fromRGBO(4, 4, 9, 0.6);

  /// OPAQUE frosted material for modal sheet bodies. Without a live backdrop
  /// blur, a translucent fill lets the content behind bleed through and reads
  /// muddy — so sheets use this fully-opaque dark gradient (subtle top sheen)
  /// and lift their inner cards with a lighter [glassFill] on top.
  static const LinearGradient sheetSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF222229), Color(0xFF161619)],
  );

  /// Top fade for status-bar legibility over the ambient background.
  static const LinearGradient topFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromRGBO(7, 7, 12, 0.92), Color.fromRGBO(7, 7, 12, 0)],
    stops: [0.3, 1.0],
  );

  // ── Ambient background blobs ───────────────────────────────
  // Slowly drifting colour fields the glass refracts. Gold + violet + teal +
  // red, low alpha, heavily blurred.
  static const Color ambientViolet = Color(0xFF7C3AED);
  static const Color ambientTeal = Color(0xFF12A594);
  static const Color ambientRed = Color(0xFFE5484D);
}
