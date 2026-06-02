import 'package:go_router/go_router.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsy/features/notifications/presentation/notification_settings_screen.dart';
import 'package:subsy/features/onboarding/presentation/onboarding_screen.dart';
import 'package:subsy/features/statistics/presentation/statistics_screen.dart';
import 'package:subsy/features/subscription_import/presentation/import_screen.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_form_screen.dart';

/// Route name constants — no magic strings (see CONSTITUTION.md).
abstract final class Routes {
  const Routes._();
  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
  static const String addSubscription = '/subscription/add';
  static const String importSubscription = '/subscription/import';
  static const String subscriptionDetail = '/subscription/detail'; // extra: Subscription
  static const String editSubscription = '/subscription/edit'; // extra: Subscription
  static const String notificationSettings = '/settings/notifications';
  static const String statistics = '/statistics';
}

/// Builds the app router. [initialLocation] is resolved once at startup — the
/// onboarding gate picks `/onboarding` for first-run users and `/` otherwise,
/// so there is no reactive redirect (and no first-frame flash).
GoRouter createAppRouter({String initialLocation = Routes.dashboard}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.addSubscription,
      builder: (context, state) => const SubscriptionFormScreen(),
    ),
    GoRoute(
      path: Routes.importSubscription,
      builder: (context, state) => const ImportScreen(),
    ),
    GoRoute(
      path: Routes.subscriptionDetail,
      builder: (context, state) =>
          SubscriptionDetailScreen(subscription: state.extra as Subscription),
    ),
    GoRoute(
      path: Routes.editSubscription,
      builder: (context, state) =>
          SubscriptionFormScreen(subscription: state.extra as Subscription?),
    ),
    GoRoute(
      path: Routes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: Routes.statistics,
      builder: (context, state) => const StatisticsScreen(),
    ),
  ],
);
