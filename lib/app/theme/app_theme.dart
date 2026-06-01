import 'package:flutter/material.dart';

/// Central theme definition. Dark mode is the primary, mandatory theme
/// (see CONSTITUTION.md — "Dark mode zorunlu"). Light theme is optional/later.
abstract final class AppTheme {
  const AppTheme._();

  /// Brand seed used for the neutral app chrome. Per-subscription brand colors
  /// are applied at the card level, not here.
  static const Color _seed = Color(0xFF6C5CE7);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E0E12),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
