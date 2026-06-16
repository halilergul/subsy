import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:subsy/features/onboarding/application/onboarding_providers.dart';
import 'package:subsy/features/onboarding/presentation/onboarding_screen.dart';

import '../support/fakes.dart';

/// US1/US2 — onboarding carousel: skip completes, the last slide reveals the
/// notification pre-prompt, and postponing still completes (non-blocking).
void main() {
  late FakeOnboardingRepository repo;

  Widget harness() {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('DASHBOARD-STUB'))),
      ],
    );
    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  setUp(() {
    repo = FakeOnboardingRepository();
    // Freeze the ambient-background drift so pumpAndSettle can settle.
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('shows the first slide and a skip action', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.text('Aboneliklerini tek yerde topla'), findsOneWidget);
    expect(find.text('Atla'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
  });

  testWidgets('skip completes onboarding and routes to the app', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    expect(repo.markCount, 1);
    expect(repo.completed, isTrue);
    expect(find.text('DASHBOARD-STUB'), findsOneWidget);
  });

  testWidgets('last slide reveals the notification pre-prompt, postpone completes',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Advance through to the last slide.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('İleri'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Zamanında haberdar ol'), findsOneWidget);
    expect(find.text('Atla'), findsNothing); // skip hidden on last slide

    // "Başla" surfaces the in-context notification pre-prompt.
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.text('Bildirimleri Aç'), findsOneWidget);
    expect(find.text('Şimdilik geç'), findsOneWidget);

    // Postponing still completes — never blocks.
    await tester.tap(find.text('Şimdilik geç'));
    await tester.pumpAndSettle();
    expect(repo.markCount, 1);
    expect(find.text('DASHBOARD-STUB'), findsOneWidget);
  });
}
