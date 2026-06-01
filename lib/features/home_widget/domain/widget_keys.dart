// Shared identifiers for the home-screen widget. No magic strings: the Dart
// publisher and the native widgets (Android provider, iOS WidgetKit) agree on
// these exact key names + target names.

// Widget data keys (primitive String values written via home_widget).
const String kWidgetStateKey = 'state';
const String kWidgetNextTitleKey = 'next_title';
const String kWidgetNextWhenKey = 'next_when';
const String kWidgetNextAmountKey = 'next_amount';
const String kWidgetNextServiceKeyKey = 'next_service_key';
const String kWidgetTotalLineKey = 'total_line';
const String kWidgetUnifiedLineKey = 'unified_line';

// Native widget target names (must match the Android receiver class + iOS kind).
const String kAndroidWidgetProvider = 'SubsyWidgetProvider';
const String kIosWidgetName = 'SubsyWidget';

/// iOS App Group used to share widget data between the app and the extension.
const String kWidgetAppGroupId = 'group.com.halilergul.subsy';
