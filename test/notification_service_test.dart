import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/core/services/notification_service.dart';
import 'package:smsvora/data/conversation_repository.dart';
import 'package:smsvora/data/models/message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset notification service callbacks
    NotificationService.instance.onOtpCopied = null;
    NotificationService.instance.onCallBack = null;
    NotificationService.instance.onReplySubmitted = null;
    NotificationService.instance.onOpenConversation = null;
  });

  group('NotificationService Detection & Actions', () {
    test('isMissedCallMessage correctly detects missed call patterns', () {
      final service = NotificationService.instance;

      expect(
        service.isMissedCallMessage('You have a missed call from +91 98765 43210'),
        isTrue,
      );
      expect(
        service.isMissedCallMessage('Missed call alert: 9876543210 at 10:45 AM'),
        isTrue,
      );
      expect(
        service.isMissedCallMessage('Riya tried calling you at 3:15 PM'),
        isTrue,
      );
      expect(
        service.isMissedCallMessage('Hey, did you review the mockups?'),
        isFalse,
      );
      expect(
        service.isMissedCallMessage('482910 is your OTP for HDFC Bank card'),
        isFalse,
      );
    });

    test('extractCallBackPhone extracts phone number or uses fallback', () {
      final service = NotificationService.instance;

      expect(
        service.extractCallBackPhone(
          'Missed call from 9876543210 at 11:00 AM',
          '+91 12345 67890',
        ),
        '9876543210',
      );

      expect(
        service.extractCallBackPhone(
          'You missed a call',
          '+91 98450 21490',
        ),
        '+91 98450 21490',
      );
    });

    test('handleNotificationResponse handles copy_otp action', () async {
      String? copiedOtp;
      NotificationService.instance.onOtpCopied = (otp) {
        copiedOtp = otp;
      };

      // Mock clipboard messenger
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          return null;
        }
        return null;
      });

      // Simulate notification response for copy_otp
      // NotificationResponse with actionId 'copy_otp'
      await NotificationService.instance.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'copy_otp',
          payload: '{"convId":"conv_1","otp":"482910","phone":"+919876543210"}',
        ),
      );

      expect(copiedOtp, equals('482910'));
    });

    test('handleNotificationResponse handles call_back action', () async {
      String? dialedPhone;
      NotificationService.instance.onCallBack = (phone) {
        dialedPhone = phone;
      };

      await NotificationService.instance.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'call_back',
          payload: '{"convId":"conv_1","otp":"","phone":"+919876543210"}',
        ),
      );

      expect(dialedPhone, equals('+919876543210'));
    });

    test('handleNotificationResponse handles inline reply action and updates repository', () async {
      String? replyConvId;
      String? submittedText;

      NotificationService.instance.onReplySubmitted = (convId, text) {
        replyConvId = convId;
        submittedText = text;
        ConversationRepository.instance.addOutgoingReply(convId, text);
      };

      const targetConvId = 'conv_1';
      final initialCount =
          ConversationRepository.instance.getConversation(targetConvId)!.messages.length;

      await NotificationService.instance.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'reply',
          input: 'Thanks, I will join in 5 minutes!',
          payload: '{"convId":"$targetConvId","otp":"","phone":"+919876543210"}',
        ),
      );

      expect(replyConvId, equals(targetConvId));
      expect(submittedText, equals('Thanks, I will join in 5 minutes!'));

      // Check repository was updated
      final updatedConv =
          ConversationRepository.instance.getConversation(targetConvId)!;
      expect(updatedConv.messages.length, equals(initialCount + 1));
      expect(updatedConv.messages.last.sender, equals(MessageSender.me));
      expect(
        updatedConv.messages.last.text,
        equals('Thanks, I will join in 5 minutes!'),
      );
    });

    test('handleNotificationResponse handles tapping notification body to open conversation', () async {
      String? openedConvId;
      NotificationService.instance.onOpenConversation = (convId) {
        openedConvId = convId;
      };

      await NotificationService.instance.handleNotificationResponse(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '{"convId":"conv_2","otp":"","phone":"+919845021490"}',
        ),
      );

      expect(openedConvId, equals('conv_2'));
    });
  });

  group('Incoming Message Reception in ConversationRepository', () {
    test('receiveIncomingMessage adds message and classifies OTP correctly', () async {
      final hdfcBefore = ConversationRepository.instance
          .conversations
          .firstWhere((c) => c.name == 'HDFC Bank');
      final beforeCount = hdfcBefore.messages.length;

      await ConversationRepository.instance.receiveIncomingMessage(
        senderPhone: hdfcBefore.phone,
        senderName: 'HDFC Bank',
        text: '948201 is your OTP for transaction at Amazon. Valid for 10 mins.',
        triggerNotification: false,
      );

      final hdfcAfter = ConversationRepository.instance
          .conversations
          .firstWhere((c) => c.name == 'HDFC Bank');
      expect(hdfcAfter.messages.length, equals(beforeCount + 1));
      expect(hdfcAfter.messages.last.otp, equals('948201'));
      expect(hdfcAfter.unread, greaterThan(0));

      // Test completely new sender creates new conversation
      final initialLength = ConversationRepository.instance.conversations.length;
      await ConversationRepository.instance.receiveIncomingMessage(
        senderPhone: '+91 77777 88888',
        senderName: 'New Contact',
        text: 'Hello from a new sender!',
        triggerNotification: false,
      );
      expect(
        ConversationRepository.instance.conversations.length,
        equals(initialLength + 1),
      );
    });

    test('receiveIncomingMessage for missed call records message properly', () async {
      await ConversationRepository.instance.receiveIncomingMessage(
        senderPhone: '+91 88888 22222',
        senderName: 'Aman Shah',
        text: 'Missed call alert: Aman Shah tried calling you at 11:30 AM.',
        triggerNotification: false,
      );

      final conv = ConversationRepository.instance.conversations.first;
      expect(conv.name, equals('Aman Shah'));
      expect(
        NotificationService.instance.isMissedCallMessage(conv.messages.last.text),
        isTrue,
      );
    });
  });
}
