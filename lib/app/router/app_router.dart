import 'package:go_router/go_router.dart';
import 'package:subsy/features/dashboard/presentation/dashboard_screen.dart';

/// Route name constants — no magic strings (see CONSTITUTION.md).
abstract final class Routes {
  const Routes._();
  static const String dashboard = '/';
}

/// App router. Kept simple for the scaffold; feature routes are added as
/// each feature lands.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.dashboard,
  routes: [
    GoRoute(
      path: Routes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
