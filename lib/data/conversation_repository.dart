import 'package:flutter/foundation.dart';

import '../core/ml/company_extractor.dart';
import '../core/ml/otp_detector.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import 'models/conversation.dart';
import 'models/message.dart';
import 'sample_data.dart';

class ConversationRepository extends ChangeNotifier {
  ConversationRepository._() {
    _conversations = List.from(SampleData.conversations);
  }

  static final ConversationRepository instance = ConversationRepository._();

  List<Conversation> _conversations = [];

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  Conversation? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Appends an outgoing reply to a conversation.
  void addOutgoingReply(String convId, String text) {
    final index = _conversations.indexWhere((c) => c.id == convId);
    if (index == -1) return;

    final conv = _conversations[index];
    final now = DateTime.now();
    final timeStr = _formatTime(now);

    final replyMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.me,
      text: text,
      time: timeStr,
      date: 'Today',
      status: MessageStatus.sent,
      category: conv.category,
      timestamp: now,
    );

    final updatedMessages = List<Message>.from(conv.messages)..add(replyMessage);

    final updatedConv = conv.copyWith(
      messages: updatedMessages,
      lastTime: timeStr,
    );

    _conversations[index] = updatedConv;
    _moveToTop(index);
    notifyListeners();
  }

  /// Receives an incoming message and triggers a rich notification.
  Future<void> receiveIncomingMessage({
    required String senderPhone,
    required String senderName,
    required String text,
    String? otp,
    bool triggerNotification = true,
  }) async {
    final now = DateTime.now();
    final timeStr = _formatTime(now);

    // 1. Detect OTP
    final detectedOtp = otp ?? OtpDetector.detect(text)?.code;

    // 2. Classify sender and organization
    final companyIdentity = CompanyExtractor.extract(senderName, text);

    // 3. Find matching conversation or create new
    int index = _conversations.indexWhere(
      (c) => c.phone == senderPhone || (senderName.isNotEmpty && c.name == senderName),
    );

    late Conversation conv;
    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final incomingMsg = Message(
      id: messageId,
      sender: MessageSender.them,
      text: text,
      time: timeStr,
      date: 'Today',
      status: MessageStatus.delivered,
      category: companyIdentity?.category ??
          (detectedOtp != null
              ? ConversationCategory.otp
              : ConversationCategory.personal),
      otp: detectedOtp,
      timestamp: now,
    );

    if (index != -1) {
      conv = _conversations[index];
      final updatedMessages = List<Message>.from(conv.messages)..add(incomingMsg);
      conv = conv.copyWith(
        messages: updatedMessages,
        lastTime: timeStr,
        unread: conv.unread + 1,
      );
      _conversations[index] = conv;
      _moveToTop(index);
    } else {
      conv = Conversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        name: senderName.isNotEmpty ? senderName : senderPhone,
        phone: senderPhone,
        initials: _getInitials(senderName.isNotEmpty ? senderName : senderPhone),
        avatarBgColor: AppColors.deepForest,
        avatarTextColor: AppColors.softCream,
        category: companyIdentity?.category ??
            (detectedOtp != null
                ? ConversationCategory.otp
                : ConversationCategory.personal),
        pinned: false,
        unread: 1,
        muted: false,
        lastTime: timeStr,
        carrier: 'SIM 1',
        companyName: companyIdentity?.companyName ?? '',
        companyFolder: companyIdentity?.parentFolder ?? '',
        parentFolder: companyIdentity?.parentFolder ?? '',
        subFolder: companyIdentity?.subFolder ?? '',
        messages: [incomingMsg],
      );
      _conversations.insert(0, conv);
    }

    notifyListeners();

    // 4. Trigger system notification with interactive action buttons
    if (triggerNotification) {
      await NotificationService.instance.showMessageNotification(
        conversation: conv,
        message: incomingMsg,
      );
    }
  }

  void markAsRead(String convId) {
    final index = _conversations.indexWhere((c) => c.id == convId);
    if (index != -1 && _conversations[index].unread > 0) {
      _conversations[index] = _conversations[index].copyWith(unread: 0);
      notifyListeners();
    }
  }

  void togglePin(String convId) {
    final index = _conversations.indexWhere((c) => c.id == convId);
    if (index != -1) {
      final current = _conversations[index];
      _conversations[index] = current.copyWith(pinned: !current.pinned);
      notifyListeners();
    }
  }

  void deleteConversation(String convId) {
    _conversations.removeWhere((c) => c.id == convId);
    notifyListeners();
  }

  void _moveToTop(int index) {
    if (index > 0 && index < _conversations.length) {
      final item = _conversations.removeAt(index);
      _conversations.insert(0, item);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'SV';
  }
}
