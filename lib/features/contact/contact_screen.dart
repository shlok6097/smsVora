import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/conversation.dart';

class ContactScreen extends StatefulWidget {
  final Conversation conversation;

  const ContactScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late Conversation _conversation;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
  }

  void _togglePin() {
    setState(() {
      _conversation = Conversation(
        id: _conversation.id,
        name: _conversation.name,
        phone: _conversation.phone,
        initials: _conversation.initials,
        avatarBgColor: _conversation.avatarBgColor,
        avatarTextColor: _conversation.avatarTextColor,
        category: _conversation.category,
        pinned: !_conversation.pinned,
        unread: _conversation.unread,
        muted: _conversation.muted,
        lastTime: _conversation.lastTime,
        carrier: _conversation.carrier,
        messages: _conversation.messages,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _conversation.pinned
              ? 'Conversation pinned'
              : 'Conversation unpinned',
        ),
        backgroundColor: AppColors.deepEspresso,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _conversation = Conversation(
        id: _conversation.id,
        name: _conversation.name,
        phone: _conversation.phone,
        initials: _conversation.initials,
        avatarBgColor: _conversation.avatarBgColor,
        avatarTextColor: _conversation.avatarTextColor,
        category: _conversation.category,
        pinned: _conversation.pinned,
        unread: _conversation.unread,
        muted: !_conversation.muted,
        lastTime: _conversation.lastTime,
        carrier: _conversation.carrier,
        messages: _conversation.messages,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _conversation.muted
              ? 'Notifications muted'
              : 'Notifications unmuted',
        ),
        backgroundColor: AppColors.deepEspresso,
        duration: const Duration(seconds: 2),
      ),
    );
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, _conversation),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.greigeStone,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.deepEspresso,
                        ),
                      ),
                    ),
                    const Text(
                      'Contact Info',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepEspresso,
                      ),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // Profile Hero
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _conversation.avatarBgColor,
                            child: Text(
                              _conversation.initials,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _conversation.avatarTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _conversation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepEspresso,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _conversation.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.chestnut,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Row (Call, Pin, Mute)
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Call',
                            backgroundColor: AppColors.greigeStone,
                            textColor: AppColors.deepEspresso,
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
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: _conversation.pinned ? 'Pinned' : 'Pin',
                            backgroundColor: _conversation.pinned
                                ? AppColors.chestnut
                                : AppColors.greigeStone,
                            textColor: _conversation.pinned
                                ? AppColors.softCream
                                : AppColors.deepEspresso,
                            onTap: _togglePin,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: _conversation.muted ? 'Muted' : 'Mute',
                            backgroundColor: _conversation.muted
                                ? AppColors.deepEspresso
                                : AppColors.greigeStone,
                            textColor: _conversation.muted
                                ? AppColors.softCream
                                : AppColors.deepEspresso,
                            onTap: _toggleMute,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Shared Links & Media
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.extraLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.greigeStone, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Shared Links & Media',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEspresso,
                                ),
                              ),
                              Text(
                                '3 items',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.chestnut,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.chestnut,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Palette.png',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.softCream,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.warmTaupe,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Mockup.fig',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepEspresso,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.greigeStone,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Spec.pdf',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepEspresso,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thread Options
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.greigeStone,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Default Route',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepEspresso,
                                  ),
                                ),
                                Text(
                                  _conversation.carrier.isNotEmpty
                                      ? _conversation.carrier
                                      : 'SMS · SIM 1',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.chestnut,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.warmTaupe,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Block & Report Spam',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepEspresso,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Contact blocked & moved to spam',
                                        ),
                                        backgroundColor: AppColors.deepEspresso,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Block',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.chestnut,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
