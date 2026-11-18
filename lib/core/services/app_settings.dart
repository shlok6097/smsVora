import '../../data/models/conversation.dart';

class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // Preferences
  bool deliveryReports = true;
  bool autoOrganizeOtps = true;
  bool rcsFallback = true;

  // Auto-delete expired OTPs after 24 hours (default: false / off)
  bool deleteExpiredOtps = false;

  // Automated UPI registration / SIM device binding SMS (default: true / on)
  bool allowAutomatedUpi = true;

  final String soundTone = 'Warm Woodblock';
  final String bubbleRadius = 'Rounded (20px)';

  /// Automatically purges OTP messages that expired more than 24 hours ago.
  /// Returns the number of removed messages.
  int cleanExpiredOtps(List<Conversation> conversations) {
    if (!deleteExpiredOtps) return 0;

    final now = DateTime.now();
    int deletedCount = 0;

    for (int i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      final originalCount = conv.messages.length;

      final remainingMessages = conv.messages.where((msg) {
        if (msg.otp != null && msg.otpExpiresAt != null) {
          // Expired more than 24 hours ago
          final deleteThreshold =
              msg.otpExpiresAt!.add(const Duration(hours: 24));
          if (now.isAfter(deleteThreshold)) {
            deletedCount++;
            return false;
          }
        }
        return true;
      }).toList();

      if (remainingMessages.length != originalCount) {
        conversations[i] = conv.copyWith(messages: remainingMessages);
      }
    }

    return deletedCount;
  }
}
