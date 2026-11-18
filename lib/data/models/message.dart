import 'conversation.dart';

enum MessageSender { me, them }

enum MessageStatus { sent, delivered, read, failed }

class Message {
  final String id;
  final MessageSender sender;
  final String text;
  final String time;
  final String date;
  final MessageStatus status;
  final String? otp;
  final Duration? otpExpiryDuration;
  final DateTime? otpExpiresAt;
  final DateTime? timestamp;
  final ConversationCategory category;

  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.date,
    this.status = MessageStatus.delivered,
    this.otp,
    this.otpExpiryDuration,
    this.otpExpiresAt,
    this.timestamp,
    this.category = ConversationCategory.personal,
  });

  DateTime get sortTimestamp {
    if (timestamp != null) return timestamp!;
    if (otpExpiresAt != null && otpExpiryDuration != null) {
      return otpExpiresAt!.subtract(otpExpiryDuration!);
    }
    if (otpExpiresAt != null) {
      return otpExpiresAt!.subtract(const Duration(minutes: 5));
    }
    final now = DateTime.now();
    DateTime baseDate = now;
    if (date.toLowerCase().contains('yesterday')) {
      baseDate = now.subtract(const Duration(days: 1));
    } else if (!date.toLowerCase().contains('today')) {
      baseDate = now.subtract(const Duration(days: 2));
    }

    try {
      final parts = time.trim().split(RegExp(r'[:\s]'));
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);
        if (time.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (time.toLowerCase().contains('am') && hour == 12) hour = 0;
        return DateTime(
            baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }
    } catch (_) {}

    return baseDate;
  }

  bool get isOtpExpired {
    if (otp == null || otpExpiresAt == null) return false;
    return DateTime.now().isAfter(otpExpiresAt!);
  }

  String? get formattedExpiryRemaining {
    if (otp == null || otpExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(otpExpiresAt!)) {
      return 'Expired';
    }
    final difference = otpExpiresAt!.difference(now);
    final minutes = difference.inMinutes;
    final seconds = difference.inSeconds % 60;
    if (minutes > 0) {
      return 'Expires in ${minutes}m ${seconds}s';
    } else {
      return 'Expires in ${seconds}s';
    }
  }

  Message copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    String? time,
    String? date,
    MessageStatus? status,
    String? otp,
    Duration? otpExpiryDuration,
    DateTime? otpExpiresAt,
    DateTime? timestamp,
    ConversationCategory? category,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      time: time ?? this.time,
      date: date ?? this.date,
      status: status ?? this.status,
      otp: otp ?? this.otp,
      otpExpiryDuration: otpExpiryDuration ?? this.otpExpiryDuration,
      otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
    );
  }
}
