import 'package:go_router/go_router.dart';
import 'package:subsy/features/notifications/presentation/notification_settings_screen.dart';
import 'package:subsy/features/onboarding/presentation/onboarding_screen.dart';
import 'package:subsy/features/shell/presentation/glass_shell.dart';

/// Route name constants — no magic strings (see CONSTITUTION.md).
///
/// The dashboard, statistics, settings, subscription detail and add/edit form
/// are no longer separate routes: the Liquid-Glass shell hosts the four tabs,
/// and detail / add / paywall open as glass bottom sheets. Only genuinely
/// pushed destinations remain here.
abstract final class Routes {
  const Routes._();
  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
  static const String notificationSettings = '/settings/notifications';
}

/// Builds the app router. [initialLocation] is resolved once at startup — the
/// onboarding gate picks `/onboarding` for first-run users and `/` otherwise,
/// so there is no reactive redirect (and no first-frame flash).
GoRouter createAppRouter({
  String initialLocation = Routes.dashboard,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) => const GlassShell(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
  ],
);
