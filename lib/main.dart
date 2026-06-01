import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_theme.dart';
import 'package:subsy/core/exchange/http_exchange_rate_service.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/application/exchange_rate_sync.dart';
import 'package:subsy/features/home_widget/application/home_widget_providers.dart';
import 'package:subsy/features/home_widget/application/home_widget_sync.dart';
import 'package:subsy/features/home_widget/data/plugin_home_widget_service.dart';
import 'package:subsy/features/home_widget/domain/widget_keys.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/data/local_notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone setup for correct local, DST-safe reminder scheduling.
  tzdata.initializeTimeZones();
  final localZone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localZone.identifier));

  // Initialize the notification plugin once and inject the adapter.
  final scheduler = LocalNotificationService(FlutterLocalNotificationsPlugin());
  await scheduler.init();

  // Share home-widget data with the iOS widget extension via the App Group.
  await HomeWidget.setAppGroupId(kWidgetAppGroupId);

  runApp(
    ProviderScope(
      overrides: [
        notificationSchedulerProvider.overrideWithValue(scheduler),
        exchangeRateServiceProvider
            .overrideWithValue(HttpExchangeRateService(http.Client())),
        homeWidgetServiceProvider.overrideWithValue(const PluginHomeWidgetService()),
      ],
      child: const SubsyApp(),
    ),
  );
}

class SubsyApp extends ConsumerWidget {
  const SubsyApp({super.key});

  /// Turkish-only UI for v1 (see CONSTITUTION.md — i18n).
  static const Locale _locale = Locale('tr');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate reactive reminder rescheduling for the app's lifetime.
    startReminderSync(ref);
    // Best-effort exchange-rate refresh (cache-first; offline-safe).
    startExchangeRateSync(ref);
    // Keep the home-screen widget in sync with subscriptions/rates/premium.
    startHomeWidgetSync(ref);

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
