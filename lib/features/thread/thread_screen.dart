import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ml/tinybert_service.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';

class ThreadScreen extends StatefulWidget {
  final Conversation conversation;

  const ThreadScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late Conversation _conversation;
  late List<Message> _messages;
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _otpTimer;

  final List<String> _quickReplies = [
    'On my way!',
    'Sounds good',
    'Call you in 5 mins',
  ];

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _messages = List.from(widget.conversation.messages);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Mark messages as read
    if (_conversation.unread > 0) {
      _conversation = Conversation(
        id: _conversation.id,
        name: _conversation.name,
        phone: _conversation.phone,
        initials: _conversation.initials,
        avatarBgColor: _conversation.avatarBgColor,
        avatarTextColor: _conversation.avatarTextColor,
        category: _conversation.category,
        pinned: _conversation.pinned,
        unread: 0,
        muted: _conversation.muted,
        lastTime: _conversation.lastTime,
        carrier: _conversation.carrier,
        messages: _messages,
      );
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textOverride]) {
    final text = (textOverride ?? _replyController.text).trim();
    if (text.isEmpty) return;

    final bertResult = TinyBertService.instance.classify(
      messageText: text,
      senderHeader: _conversation.phone,
    );

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.me,
      text: text,
      time: 'Just now',
      date: 'Today',
      status: MessageStatus.delivered,
      otp: bertResult.otpResult?.code,
      otpExpiryDuration: bertResult.otpResult?.expiryDuration,
      otpExpiresAt: bertResult.otpResult?.expiresAt,
      category: bertResult.category,
    );

    setState(() {
      _messages.add(newMessage);
      _conversation = Conversation(
        id: _conversation.id,
        name: _conversation.name,
        phone: _conversation.phone,
        initials: _conversation.initials,
        avatarBgColor: _conversation.avatarBgColor,
        avatarTextColor: _conversation.avatarTextColor,
        category: _conversation.category,
        pinned: _conversation.pinned,
        unread: 0,
        muted: _conversation.muted,
        lastTime: 'Just now',
        carrier: _conversation.carrier,
        companyName: _conversation.companyName,
        companyFolder: _conversation.companyFolder,
        messages: _messages,
      );
      if (textOverride == null) {
        _replyController.clear();
      }
    });

    _scrollToBottom();
  }

  void _copyOtp(String otp) {
    Clipboard.setData(ClipboardData(text: otp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP $otp copied'),
        backgroundColor: AppColors.deepEspresso,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onOpenContact() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRouter.contact,
      arguments: _conversation,
    );

    if (updated is Conversation) {
      setState(() {
        _conversation = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _conversation);
      },
      child: Scaffold(
        backgroundColor: AppColors.softCream,
        body: SafeArea(
          child: Column(
            children: [
              // Thread Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.softCream,
                  border: Border(
                    bottom: BorderSide(color: AppColors.greigeStone, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    _CircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      iconSize: 16,
                      onTap: () => Navigator.pop(context, _conversation),
                    ),
                    const SizedBox(width: 10),

                    // Contact Info
                    Expanded(
                      child: InkWell(
                        onTap: _onOpenContact,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: _conversation.avatarBgColor,
                                child: Text(
                                  _conversation.initials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _conversation.avatarTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _conversation.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepEspresso,
                                      ),
                                    ),
                                    Text(
                                      _conversation.carrier.isNotEmpty
                                          ? _conversation.carrier
                                          : _conversation.phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.chestnut,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    _CircleButton(
                      icon: Icons.call_outlined,
                      iconSize: 18,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Dialing ${_conversation.name} (${_conversation.phone})...',
                            ),
                            backgroundColor: AppColors.deepEspresso,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _CircleButton(
                      icon: Icons.info_outline_rounded,
                      iconSize: 18,
                      onTap: _onOpenContact,
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    // Date pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greigeStone,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message bubbles
                    ..._messages.map((m) {
                      final isMe = m.sender == MessageSender.me;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.chestnut
                                    : AppColors.greigeStone,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isMe
                                          ? AppColors.softCream
                                          : AppColors.deepEspresso,
                                    ),
                                  ),
                                  if (m.otp != null) ...[
                                    const SizedBox(height: 8),
                                    if (m.formattedExpiryRemaining != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 13,
                                              color: m.isOtpExpired
                                                  ? Colors.red[800]
                                                  : (isMe ? AppColors.softCream : AppColors.deepForest),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              m.formattedExpiryRemaining!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: m.isOtpExpired
                                                  ? Colors.red[800]
                                                  : (isMe ? AppColors.softCream : AppColors.deepForest),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    InkWell(
                                      onTap: () => _copyOtp(m.otp!),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 7),
                                        decoration: BoxDecoration(
                                          color: m.isOtpExpired
                                              ? AppColors.warmTaupe
                                              : AppColors.deepEspresso,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Copy OTP: ${m.otp}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.softCream,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                isMe && m.status == MessageStatus.delivered
                                    ? '${m.time} · Delivered'
                                    : (isMe && m.status == MessageStatus.read
                                        ? '${m.time} · Read'
                                        : m.time),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.chestnut,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Quick Reply Chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final chipText = _quickReplies[index];
                    return InkWell(
                      onTap: () => _sendMessage(chipText),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.extraLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warmTaupe, width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          chipText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Composer Bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: const BoxDecoration(
                  color: AppColors.softCream,
                  border: Border(
                    top: BorderSide(color: AppColors.greigeStone, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.add_rounded,
                      iconSize: 20,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attachment picker: Photo, Contact, Location'),
                            backgroundColor: AppColors.deepEspresso,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.greigeStone,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _replyController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.deepEspresso,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Text message (SMS)...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xAA6E473B),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _sendMessage(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.chestnut,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 20,
                          color: AppColors.softCream,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.greigeStone,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: AppColors.deepEspresso),
      ),
    );
  }
}
