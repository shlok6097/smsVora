import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:url_launcher/url_launcher.dart';

import '../ml/otp_detector.dart';
import '../theme/app_colors.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  NotificationService.instance.handleNotificationResponse(notificationResponse);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // Callbacks for UI integration
  void Function(String conversationId)? onOpenConversation;
  void Function(String conversationId, String replyText)? onReplySubmitted;
  void Function(String otp)? onOtpCopied;
  void Function(String phoneNumber)? onCallBack;

  /// Initializes local notifications with Android notification channels and action callbacks.
  Future<void> initialize({
    void Function(String conversationId)? onOpenConversation,
    void Function(String conversationId, String replyText)? onReplySubmitted,
    void Function(String otp)? onOtpCopied,
    void Function(String phoneNumber)? onCallBack,
  }) async {
    if (_initialized) return;

    this.onOpenConversation = onOpenConversation;
    this.onReplySubmitted = onReplySubmitted;
    this.onOtpCopied = onOtpCopied;
    this.onCallBack = onCallBack;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Request notification permissions for Android 13+
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Handles user interaction on the notification (tap, Copy OTP, Call Back, or inline Reply).
  Future<void> handleNotificationResponse(
      NotificationResponse notificationResponse) async {
    final payloadString = notificationResponse.payload;
    Map<String, dynamic> payload = {};
    if (payloadString != null && payloadString.isNotEmpty) {
      try {
        payload = jsonDecode(payloadString) as Map<String, dynamic>;
      } catch (_) {
        payload = {};
      }
    }

    final String convId = payload['convId']?.toString() ?? '';
    final String otp = payload['otp']?.toString() ?? '';
    final String phone = payload['phone']?.toString() ?? '';
    final String actionId = notificationResponse.actionId ?? '';

    if (actionId == 'copy_otp') {
      if (otp.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: otp));
        onOtpCopied?.call(otp);
      }
    } else if (actionId == 'call_back') {
      if (phone.isNotEmpty) {
        try {
          final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
          final uri = Uri(scheme: 'tel', path: cleanPhone);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        } catch (_) {
          // Native dialer not available (e.g. unit tests or non-telephony devices)
        }
        onCallBack?.call(phone);
      }
    } else if (actionId == 'reply') {
      final input = notificationResponse.input;
      if (input != null && input.trim().isNotEmpty && convId.isNotEmpty) {
        onReplySubmitted?.call(convId, input.trim());
      }
    } else {
      // Tap on notification body -> navigate to conversation
      if (convId.isNotEmpty) {
        onOpenConversation?.call(convId);
      }
    }
  }

  /// Detects whether message text corresponds to a missed call notification.
  bool isMissedCallMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('missed call') ||
        lower.contains('tried calling') ||
        lower.contains('call alert') ||
        lower.contains('missed a call');
  }

  /// Extracts callback phone number from text or falls back to conversation phone.
  String extractCallBackPhone(String text, String fallbackPhone) {
    final phoneRegex = RegExp(r'(?:\+?(\d{1,3})[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
    final match = phoneRegex.firstMatch(text);
    if (match != null) {
      return match.group(0) ?? fallbackPhone;
    }
    return fallbackPhone;
  }

  /// Shows an interactive notification for an incoming SMS message.
  Future<void> showMessageNotification({
    required Conversation conversation,
    required Message message,
  }) async {
    // 1. Check for OTP
    final String? detectedOtp = message.otp ?? OtpDetector.detect(message.text)?.code;

    // 2. Check for Missed Call
    final bool isMissedCall = isMissedCallMessage(message.text);
    final String callBackPhone =
        extractCallBackPhone(message.text, conversation.phone);

    // 3. Build notification actions
    final List<AndroidNotificationAction> actions = [];

    // If OTP is present -> Copy OTP action
    if (detectedOtp != null && detectedOtp.isNotEmpty) {
      actions.add(
        const AndroidNotificationAction(
          'copy_otp',
          'Copy OTP',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      );
    }

    // If missed call -> Call Back action
    if (isMissedCall && callBackPhone.isNotEmpty) {
      actions.add(
        const AndroidNotificationAction(
          'call_back',
          'Call Back',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      );
    }

    // Reply action with Android inline RemoteInput
    actions.add(
      const AndroidNotificationAction(
        'reply',
        'Reply',
        inputs: <AndroidNotificationActionInput>[
          AndroidNotificationActionInput(
            label: 'Type a reply...',
          ),
        ],
        allowGeneratedReplies: true,
      ),
    );

    final payload = jsonEncode({
      'convId': conversation.id,
      'otp': detectedOtp ?? '',
      'phone': callBackPhone,
    });

    final notificationId = conversation.id.hashCode ^ message.id.hashCode;

    final androidDetails = AndroidNotificationDetails(
      'smsvora_messages',
      'smsVora Messages',
      channelDescription:
          'Notifications for incoming SMS messages, OTPs, and missed calls',
      importance: Importance.max,
      priority: Priority.high,
      color: AppColors.deepForest,
      actions: actions,
      styleInformation: BigTextStyleInformation(
        message.text,
        contentTitle: isMissedCall
            ? 'Missed Call Alert: ${conversation.name}'
            : conversation.name,
        summaryText: detectedOtp != null ? 'OTP Verification' : 'New SMS',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: notificationId,
      title: isMissedCall
          ? 'Missed Call Alert: ${conversation.name}'
          : conversation.name,
      body: message.text,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Cancels all active notifications.
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}
