import 'package:flutter_test/flutter_test.dart';
import 'package:velora/main.dart';

void main() {
  testWidgets('VELORA navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const VeloraApp());

    expect(find.text('Home Screen'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(find.text('Shop Screen'), findsOneWidget);
  });
}
