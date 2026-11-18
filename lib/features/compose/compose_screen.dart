import 'package:flutter/material.dart';

import '../../core/ml/tinybert_service.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/sample_data.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  String _selectedSim = 'SIM 1';
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final List<String> _templates = [
    'Running 10 mins late',
    'Call me when free',
    'Shared the location',
  ];

  @override
  void dispose() {
    _toController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onToggleSim() {
    setState(() {
      _selectedSim = _selectedSim == 'SIM 1' ? 'SIM 2' : 'SIM 1';
    });
  }

  void _sendSms() {
    final to = _toController.text.trim();
    final text = _bodyController.text.trim();

    if (to.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a recipient and message first'),
          backgroundColor: AppColors.deepEspresso,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if conversation already exists in sample data
    Conversation? existing;
    for (final c in SampleData.conversations) {
      if (c.name.toLowerCase() == to.toLowerCase() || c.phone == to) {
        existing = c;
        break;
      }
    }

    final bertResult = TinyBertService.instance.classify(
      messageText: text,
      senderHeader: to,
    );

    final newMsg = Message(
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

    final Conversation targetConv;
    if (existing != null) {
      final updatedMessages = List<Message>.from(existing.messages)..add(newMsg);
      targetConv = Conversation(
        id: existing.id,
        name: existing.name,
        phone: existing.phone,
        initials: existing.initials,
        avatarBgColor: existing.avatarBgColor,
        avatarTextColor: existing.avatarTextColor,
        category: existing.category,
        pinned: existing.pinned,
        unread: 0,
        muted: existing.muted,
        lastTime: 'Just now',
        carrier: 'SMS · $_selectedSim',
        companyName: existing.companyName,
        companyFolder: existing.companyFolder,
        messages: updatedMessages,
      );
    } else {
      final words = to.split(' ');
      final initials = words.length > 1
          ? '${words[0][0]}${words[1][0]}'.toUpperCase()
          : (to.length >= 2 ? to.substring(0, 2).toUpperCase() : 'SM');

      final companyName = bertResult.company?.companyName ?? '';
      final companyFolder = bertResult.company?.folderName ?? '';

      targetConv = Conversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        name: to,
        phone: to.startsWith('+') ? to : '+91 98000 12345',
        initials: initials,
        avatarBgColor: AppColors.chestnut,
        avatarTextColor: AppColors.softCream,
        category: bertResult.category,
        pinned: false,
        unread: 0,
        muted: false,
        lastTime: 'Just now',
        carrier: 'SMS · $_selectedSim',
        companyName: companyName,
        companyFolder: companyFolder,
        messages: [newMsg],
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS sent via $_selectedSim'),
        backgroundColor: AppColors.deepEspresso,
        duration: const Duration(seconds: 2),
      ),
    );

    // Replace current route with ThreadScreen, or pop back with targetConv
    Navigator.pushReplacementNamed(
      context,
      AppRouter.thread,
      arguments: targetConv,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.greigeStone, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greigeStone,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEspresso,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'New Message',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepEspresso,
                    ),
                  ),
                  InkWell(
                    onTap: _onToggleSim,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.deepEspresso,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _selectedSim,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.softCream,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recipient Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.greigeStone, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'To:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.chestnut,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toController,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEspresso,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Name or phone number...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.warmTaupe,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Suggested Contacts
                  const Text(
                    'SUGGESTED CONTACTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.chestnut,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...SampleData.quickContacts.map((contact) {
                    final isSelected = _toController.text == contact.name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _toController.text = contact.name;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.greigeStone
                                : AppColors.extraLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.chestnut,
                                child: Text(
                                  contact.initials,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.softCream,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepEspresso,
                                      ),
                                    ),
                                    Text(
                                      contact.phone,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.chestnut,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.deepEspresso
                                      : AppColors.warmTaupe,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isSelected ? 'Selected' : 'Select',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.softCream
                                        : AppColors.deepEspresso,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Quick SMS Templates Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.greigeStone,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick SMS Templates',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _templates.map((tpl) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _bodyController.text = tpl;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softCream,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  tpl,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepEspresso,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Message Composer & Send Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.greigeStone, width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.greigeStone,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.deepEspresso,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Write your SMS...',
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendSms,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepEspresso,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.softCream,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
