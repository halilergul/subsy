import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:subsy/app/router/app_router.dart';
import 'package:subsy/app/theme/app_theme.dart';
import 'package:subsy/core/dev/mock_seed.dart';
import 'package:subsy/core/exchange/http_exchange_rate_service.dart';
import 'package:subsy/features/currency/application/currency_providers.dart';
import 'package:subsy/features/currency/application/exchange_rate_sync.dart';
import 'package:subsy/features/home_widget/application/home_widget_providers.dart';
import 'package:subsy/features/home_widget/application/home_widget_sync.dart';
import 'package:subsy/features/home_widget/data/plugin_home_widget_service.dart';
import 'package:subsy/features/home_widget/domain/widget_keys.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/data/local_notification_service.dart';
import 'package:subsy/features/onboarding/application/onboarding_providers.dart';
import 'package:subsy/features/subscription_import/application/subscription_import_providers.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';
import 'package:subsy/features/subscription_import/data/mlkit_ocr_service.dart';
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

  final container = ProviderContainer(
    overrides: [
      notificationSchedulerProvider.overrideWithValue(scheduler),
      exchangeRateServiceProvider
          .overrideWithValue(HttpExchangeRateService(http.Client())),
      homeWidgetServiceProvider.overrideWithValue(const PluginHomeWidgetService()),
      ocrServiceProvider.overrideWithValue(const MlkitOcrService()),
    ],
  );

  // Resolve the onboarding gate before the first frame so returning users go
  // straight to the dashboard and first-run users land on onboarding — no flash.
  await container.read(isarDatabaseProvider.future);
  final onboardingDone =
      await container.read(onboardingRepositoryProvider).isCompleted();

  // TEMP: seed demo data while testing (see mock_seed.dart / kSeedMockData).
  await seedMockSubscriptions(container.read(subscriptionRepositoryProvider));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: SubsyApp(
        initialLocation:
            onboardingDone ? Routes.dashboard : Routes.onboarding,
      ),
    ),
  );
}

class SubsyApp extends ConsumerStatefulWidget {
  const SubsyApp({super.key, this.initialLocation = Routes.dashboard});

  /// Resolved by the startup onboarding gate (`/onboarding` or `/`).
  final String initialLocation;

  /// Turkish-only UI for v1 (see CONSTITUTION.md — i18n).
  static const Locale _locale = Locale('tr');

  @override
  ConsumerState<SubsyApp> createState() => _SubsyAppState();
}

class _SubsyAppState extends ConsumerState<SubsyApp> {
  // Built once so navigation state survives rebuilds.
  late final _router = createAppRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
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
      locale: SubsyApp._locale,
      supportedLocales: const [SubsyApp._locale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
