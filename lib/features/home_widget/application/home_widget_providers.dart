import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/home_widget/domain/home_widget_service.dart';

/// The home-screen widget publisher. Overridden in `main()` with the
/// plugin-backed implementation (the rest of the app/tests depend only on the
/// interface).
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  throw UnimplementedError('homeWidgetServiceProvider must be overridden in main()');
});
