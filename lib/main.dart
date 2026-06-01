import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SubsyApp()));
}

class SubsyApp extends StatelessWidget {
  const SubsyApp({super.key});

  /// Turkish-only UI for v1 (see CONSTITUTION.md — i18n).
  static const Locale _locale = Locale('tr');

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Subsy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
