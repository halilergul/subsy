import 'package:subsy/features/home_widget/domain/widget_payload.dart';

/// Publishes the widget payload to the OS home-screen widget. Hides the
/// platform plugin behind an interface so the sync/tests never depend on it.
/// Best-effort — implementations never throw (a failed publish just leaves the
/// last content in place; offline-safe).
abstract interface class HomeWidgetService {
  Future<void> publish(WidgetPayload payload);
  Future<void> clear();
}
