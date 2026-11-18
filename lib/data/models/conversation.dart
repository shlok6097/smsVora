import 'package:flutter/material.dart';
import 'message.dart';

enum ConversationCategory { personal, otp }

class Conversation {
  final String id;
  final String name;
  final String phone;
  final String initials;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final ConversationCategory category;
  final bool pinned;
  final int unread;
  final bool muted;
  final String lastTime;
  final String carrier;
  final List<Message> messages;

  const Conversation({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
    required this.avatarBgColor,
    required this.avatarTextColor,
    this.category = ConversationCategory.personal,
    this.pinned = false,
    this.unread = 0,
    this.muted = false,
    required this.lastTime,
    this.carrier = '',
    this.messages = const [],
  });
}
