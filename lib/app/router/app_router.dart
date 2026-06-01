import 'package:go_router/go_router.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsy/features/notifications/presentation/notification_settings_screen.dart';
import 'package:subsy/features/statistics/presentation/statistics_screen.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/features/subscriptions/presentation/subscription_form_screen.dart';

/// Route name constants — no magic strings (see CONSTITUTION.md).
abstract final class Routes {
  const Routes._();
  static const String dashboard = '/';
  static const String addSubscription = '/subscription/add';
  static const String editSubscription = '/subscription/edit'; // extra: Subscription
  static const String notificationSettings = '/settings/notifications';
  static const String statistics = '/statistics';
}

/// App router. Feature routes are added as each feature lands.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.dashboard,
  routes: [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: Routes.addSubscription,
      builder: (context, state) => const SubscriptionFormScreen(),
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
