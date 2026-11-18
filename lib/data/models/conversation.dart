import 'package:flutter/material.dart';
import 'message.dart';

enum ConversationCategory {
  personal,
  otp,
  banking,
  deliveries,
  actions,
  spam,
}

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
  final String companyName;
  final String companyFolder;
  final String parentFolder;
  final String subFolder;
  final bool isSpam;
  final String? spamReason;
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
    this.companyName = '',
    this.companyFolder = '',
    this.parentFolder = '',
    this.subFolder = '',
    this.isSpam = false,
    this.spamReason,
    this.messages = const [],
  });

  Conversation copyWith({
    String? id,
    String? name,
    String? phone,
    String? initials,
    Color? avatarBgColor,
    Color? avatarTextColor,
    ConversationCategory? category,
    bool? pinned,
    int? unread,
    bool? muted,
    String? lastTime,
    String? carrier,
    String? companyName,
    String? companyFolder,
    String? parentFolder,
    String? subFolder,
    bool? isSpam,
    String? spamReason,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      initials: initials ?? this.initials,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      avatarTextColor: avatarTextColor ?? this.avatarTextColor,
      category: category ?? this.category,
      pinned: pinned ?? this.pinned,
      unread: unread ?? this.unread,
      muted: muted ?? this.muted,
      lastTime: lastTime ?? this.lastTime,
      carrier: carrier ?? this.carrier,
      companyName: companyName ?? this.companyName,
      companyFolder: companyFolder ?? this.companyFolder,
      parentFolder: parentFolder ?? this.parentFolder,
      subFolder: subFolder ?? this.subFolder,
      isSpam: isSpam ?? this.isSpam,
      spamReason: spamReason ?? this.spamReason,
      messages: messages ?? this.messages,
    );
  }
}
