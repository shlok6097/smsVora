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

  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    required this.date,
    this.status = MessageStatus.delivered,
    this.otp,
  });
}
