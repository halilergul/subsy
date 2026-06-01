import 'package:subsy/features/home_widget/domain/widget_keys.dart';

/// Which layout branch the native widget renders.
enum WidgetState { ready, empty, locked }

/// Display-ready snapshot pushed to the home-screen widget. All strings are
/// already formatted in Turkish so the native widget only renders text (logic
/// stays in Dart). Not user data leaving the device — written to the plugin's
/// on-device key/value store the widget reads.
class WidgetPayload {
  const WidgetPayload({
    required this.state,
    this.nextTitle = '',
    this.nextWhen = '',
    this.nextAmount = '',
    this.nextServiceKey = '',
    this.totalLine = '',
    this.unifiedLine = '',
  });

  const WidgetPayload.empty() : this(state: WidgetState.empty);
  const WidgetPayload.locked() : this(state: WidgetState.locked);

  final WidgetState state;
  final String nextTitle;
  final String nextWhen;
  final String nextAmount;
  final String nextServiceKey;
  final String totalLine;
  final String unifiedLine;

  /// Fixed primitive key/value map written via `HomeWidget.saveWidgetData`.
  Map<String, String> toMap() => {
        kWidgetStateKey: state.name,
        kWidgetNextTitleKey: nextTitle,
        kWidgetNextWhenKey: nextWhen,
        kWidgetNextAmountKey: nextAmount,
        kWidgetNextServiceKeyKey: nextServiceKey,
        kWidgetTotalLineKey: totalLine,
        kWidgetUnifiedLineKey: unifiedLine,
      };
}
