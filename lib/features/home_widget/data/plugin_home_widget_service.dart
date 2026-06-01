import 'package:home_widget/home_widget.dart';
import 'package:subsy/features/home_widget/domain/home_widget_service.dart';
import 'package:subsy/features/home_widget/domain/widget_keys.dart';
import 'package:subsy/features/home_widget/domain/widget_payload.dart';

/// `home_widget`-backed implementation: writes each payload key, then asks the
/// OS to refresh the Android/iOS widgets. Best-effort — any plugin error is
/// swallowed so a failed publish never disrupts the app (offline-safe).
class PluginHomeWidgetService implements HomeWidgetService {
  const PluginHomeWidgetService();

  @override
  Future<void> publish(WidgetPayload payload) async {
    try {
      for (final entry in payload.toMap().entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
      }
      await HomeWidget.updateWidget(
        androidName: kAndroidWidgetProvider,
        iOSName: kIosWidgetName,
      );
    } catch (_) {
      // Best-effort: leave the last published content in place.
    }
  }

  @override
  Future<void> clear() => publish(const WidgetPayload.empty());
}
