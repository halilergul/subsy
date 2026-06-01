import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/main.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('App boots to the dashboard scaffold', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The scheduler is normally injected in main(); provide a fake here.
          notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
        ],
        child: const SubsyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subsy'), findsOneWidget);
  });
}
