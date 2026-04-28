import 'package:flutter_test/flutter_test.dart';
import 'package:apsit_smart_park/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const APSITSmartParkApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(APSITSmartParkApp), findsOneWidget);
  });
}
