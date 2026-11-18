import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/core/services/app_settings.dart';
import 'package:smsvora/core/theme/app_colors.dart';
import 'package:smsvora/data/models/conversation.dart';
import 'package:smsvora/data/models/message.dart';

void main() {
  group('OTP Auto-Cleanup Tests', () {
    test('Default setting is false / off', () {
      expect(AppSettings.instance.deleteExpiredOtps, isFalse);
    });

    test('Does not delete expired OTPs when setting is off', () {
      AppSettings.instance.deleteExpiredOtps = false;

      final now = DateTime.now();
      final convs = [
        Conversation(
          id: 'test_conv',
          name: 'HDFC Bank',
          phone: 'VM-HDFCBK',
          initials: 'HB',
          avatarBgColor: AppColors.deepForest,
          avatarTextColor: AppColors.softCream,
          lastTime: '10:00 AM',
          messages: [
            Message(
              id: 'expired_48h',
              sender: MessageSender.them,
              text: 'Old OTP: 123456',
              time: '10:00 AM',
              date: '2 days ago',
              status: MessageStatus.delivered,
              otp: '123456',
              otpExpiresAt: now.subtract(const Duration(hours: 48)),
            ),
          ],
        ),
      ];

      final deleted = AppSettings.instance.cleanExpiredOtps(convs);
      expect(deleted, equals(0));
      expect(convs.first.messages.length, equals(1));
    });

    test('Automatically deletes OTPs expired more than 24 hours when setting is on', () {
      AppSettings.instance.deleteExpiredOtps = true;

      final now = DateTime.now();
      final convs = [
        Conversation(
          id: 'test_conv_active',
          name: 'HDFC Bank',
          phone: 'VM-HDFCBK',
          initials: 'HB',
          avatarBgColor: AppColors.deepForest,
          avatarTextColor: AppColors.softCream,
          lastTime: '10:00 AM',
          messages: [
            // Expired 48 hours ago -> MUST be deleted
            Message(
              id: 'expired_48h',
              sender: MessageSender.them,
              text: 'Old OTP 48h: 123456',
              time: '10:00 AM',
              date: '2 days ago',
              status: MessageStatus.delivered,
              otp: '123456',
              otpExpiresAt: now.subtract(const Duration(hours: 48)),
            ),
            // Expired 2 hours ago (< 24h grace period) -> MUST NOT be deleted
            Message(
              id: 'expired_2h',
              sender: MessageSender.them,
              text: 'Recent expired OTP: 654321',
              time: '12:00 PM',
              date: 'Today',
              status: MessageStatus.delivered,
              otp: '654321',
              otpExpiresAt: now.subtract(const Duration(hours: 2)),
            ),
            // Active OTP (expires in 5 mins) -> MUST NOT be deleted
            Message(
              id: 'active_otp',
              sender: MessageSender.them,
              text: 'Active OTP: 999999',
              time: '1:00 PM',
              date: 'Today',
              status: MessageStatus.delivered,
              otp: '999999',
              otpExpiresAt: now.add(const Duration(minutes: 5)),
            ),
          ],
        ),
      ];

      final deleted = AppSettings.instance.cleanExpiredOtps(convs);
      expect(deleted, equals(1));
      expect(convs.first.messages.length, equals(2));
      expect(convs.first.messages.any((m) => m.id == 'expired_48h'), isFalse);
      expect(convs.first.messages.any((m) => m.id == 'expired_2h'), isTrue);
      expect(convs.first.messages.any((m) => m.id == 'active_otp'), isTrue);

      // Reset to default
      AppSettings.instance.deleteExpiredOtps = false;
    });
  });
}
