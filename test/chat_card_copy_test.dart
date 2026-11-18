import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/main.dart';

void main() {
  testWidgets(
      'Chat card renders copy icon without expiry text and copies code without opening thread',
      (WidgetTester tester) async {
    // Intercept Clipboard.setData
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        final Map? args = methodCall.arguments as Map?;
        copiedText = args?['text'] as String?;
      }
      return null;
    });

    await tester.pumpWidget(const SmsVoraApp());
    await tester.pumpAndSettle();

    // Verify Messages screen is loaded
    expect(find.text('Messages'), findsOneWidget);

    // Verify expiry countdown text is REMOVED from the chat cards
    expect(find.textContaining('Expires in'), findsNothing);
    expect(find.textContaining('Expired'), findsNothing);

    // Look for the copy icon buttons on the cards
    final copyIconFinder = find.byIcon(Icons.content_copy_rounded);
    expect(copyIconFinder, findsWidgets);

    // Verify copy button displays the OTP code next to the icon
    expect(find.text('482910'), findsWidgets);

    // Tap the first copy icon button (HDFC Bank OTP)
    await tester.tap(copyIconFinder.first);
    await tester.pumpAndSettle();

    // Verify clipboard received the code
    expect(copiedText, isNotNull);
    expect(copiedText, equals('482910'));

    // Verify user is STILL on the Messages inbox screen (did NOT open the thread)
    expect(find.text('Messages'), findsOneWidget);

    // Verify floating snackbar confirmation
    expect(find.text('OTP 482910 copied to clipboard'), findsOneWidget);
  });
}
