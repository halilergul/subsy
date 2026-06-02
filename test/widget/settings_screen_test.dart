import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/settings/presentation/settings_screen.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

import '../support/fakes.dart';

/// Settings — grouped real settings + premium banner (free state).
void main() {
  Widget harness() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/settings/notifications', builder: (_, _) => const Scaffold(body: Text('NOTIF-STUB'))),
      ],
    );
    return ProviderScope(
      overrides: [
        premiumStatusProvider.overrideWith((ref) => FakePremium(false)),
        notificationSettingsProvider.overrideWith((ref) => Stream.value(NotificationSettings.defaults)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renders premium banner and grouped settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Subsy Premium'), findsOneWidget);
    expect(find.text('Bildirimler'), findsOneWidget);
    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Koyu'), findsOneWidget);
    expect(find.text('Tanıtımı tekrar göster'), findsOneWidget);
    expect(find.text('Sürüm'), findsOneWidget);
  });

  testWidgets('Bildirimler row navigates to notification settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bildirimler'));
    await tester.pumpAndSettle();
    expect(find.text('NOTIF-STUB'), findsOneWidget);
  });
}
