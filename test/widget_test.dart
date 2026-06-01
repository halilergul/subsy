import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/main.dart';

void main() {
  testWidgets('App boots to the dashboard scaffold', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SubsyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Subsy'), findsOneWidget);
  });
}
