import 'package:flutter/widgets.dart';

/// iOS (Apple Human Interface Guidelines) Dynamic Type scale, expressed as
/// reusable [TextStyle]s. The point sizes, weights, leading and tracking match
/// the SF Pro system text styles at the default ("Large") setting — unchanged
/// in iOS 26; the Liquid Glass redesign altered materials, not the type scale.
///
/// On iOS, Flutter renders these in San Francisco automatically (no
/// `fontFamily` is set, so the platform system font is used). Colors are NOT
/// baked in — apply per use with `.copyWith(color: …)` so one style can serve
/// primary/secondary text.
///
/// Reference: developer.apple.com/design/human-interface-guidelines/typography
abstract final class AppText {
  const AppText._();

  /// 34 / Bold — screen large titles (Title style at the top of a screen).
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 41 / 34,
  );

  /// 28 / Regular — Title 1.
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.36,
    height: 34 / 28,
  );

  /// 22 / Regular — Title 2.
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.26,
    height: 28 / 22,
  );

  /// 20 / Regular — Title 3.
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.45,
    height: 25 / 20,
  );

  /// 17 / Semibold — Headline. The iOS inline nav-bar title and prominent
  /// button label weight.
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.43,
    height: 22 / 17,
  );

  /// 17 / Regular — Body. The default reading size and list-row primary text.
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.43,
    height: 22 / 17,
  );

  /// 16 / Regular — Callout.
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.31,
    height: 21 / 16,
  );

  /// 15 / Regular — Subheadline. List-row secondary text.
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.23,
    height: 20 / 15,
  );

  /// 13 / Regular — Footnote. Grouped-list section headers, captions.
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 18 / 13,
  );

  /// 12 / Regular — Caption 1.
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 16 / 12,
  );

  /// 11 / Regular — Caption 2 (the smallest legible size per HIG).
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06,
    height: 13 / 11,
  );
}
