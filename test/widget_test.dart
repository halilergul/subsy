import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/shell/presentation/glass_shell.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/main.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('App boots to the Liquid Glass shell', (tester) async {
    // Freeze the ambient-background drift so the tree can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The scheduler is normally injected in main(); provide a fake here.
          notificationSchedulerProvider.overrideWithValue(FakeNotificationScheduler()),
        ],
        child: const SubsyApp(),
      ),
    );
    // Bounded pumps (not pumpAndSettle): the tab bodies show a perpetual
    // loading spinner until the Isar future resolves, which never settles
    // under the fake test clock. The shell mounts on the first frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GlassShell), findsOneWidget);
  });
}
