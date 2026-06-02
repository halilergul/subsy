import 'package:flutter/material.dart';
import 'package:subsy/app/theme/app_tokens.dart';

/// Central theme definition. Dark mode is the primary, mandatory theme
/// (see CONSTITUTION.md — "Dark mode zorunlu"). Light theme is optional/later.
/// The app-wide accent is the design's gold (AppTokens.accent); per-subscription
/// brand colors are applied at the card level, not here.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppTokens.accent,
      onPrimary: AppTokens.onAccent,
      surface: AppTokens.bg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
