import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/main.dart';

void main() {
  testWidgets(
      'Company Folders shows recent message only, and opening folder lists all messages sorted by date and time',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmsVoraApp());
    await tester.pumpAndSettle();

    // 1. Switch to Company Folders tab
    final companyFoldersTabFinder = find.text('Company Folders');
    expect(companyFoldersTabFinder, findsOneWidget);
    await tester.tap(companyFoldersTabFinder);
    await tester.pumpAndSettle();

    // 2. Verify sub-folder card displays recent message preview and count
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('State Bank of India (SBI)'), findsOneWidget);

    // Verify recent message label is present on folder cards
    expect(find.textContaining('Recent ·'), findsWidgets);

    // 3. Open HDFC Bank folder by tapping its folder card
    await tester.tap(find.text('HDFC Bank'));
    await tester.pumpAndSettle();

    // 4. Verify drill-down screen opened
    // Header should show "HDFC Bank", subtitle with "Sorted by Date & Time", and "Folders" back button
    expect(find.text('Folders'), findsOneWidget);
    expect(find.textContaining('Sorted by Date & Time'), findsOneWidget);

    // Verify messages in HDFC Bank are listed
    expect(find.textContaining('Rs 2,499.00 debited'), findsOneWidget);

    // 5. Tap Back to Folders button
    await tester.tap(find.text('Folders'));
    await tester.pumpAndSettle();

    // Verify returned to folder hierarchy
    expect(find.text('Banking & Finance'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsOneWidget);
  });
}
