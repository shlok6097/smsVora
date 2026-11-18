import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/main.dart';

void main() {
  testWidgets('smsVora inbox smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmsVoraApp());
    await tester.pumpAndSettle();

    // Verify that the Inbox screen renders with the Messages header
    expect(find.text('Messages'), findsOneWidget);
  });
}
