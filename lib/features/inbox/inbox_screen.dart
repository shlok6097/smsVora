import 'package:flutter/material.dart';

import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/sample_data.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String _activeTab = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late List<Conversation> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = List.from(SampleData.conversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _totalUnreadCount {
    return _conversations.fold(0, (sum, c) => sum + c.unread);
  }

  List<Conversation> get _filteredConversations {
    return _conversations.where((c) {
      if (_activeTab == 'unread' && c.unread == 0) return false;
      if (_activeTab == 'pinned' && !c.pinned) return false;
      if (_activeTab == 'otp' && c.category != ConversationCategory.otp) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesPhone = c.phone.toLowerCase().contains(query);
        final matchesMsg = c.messages.any((m) => m.text.toLowerCase().contains(query));
        return matchesName || matchesPhone || matchesMsg;
      }
      return true;
    }).toList();
  }

  void _onOpenThread(Conversation conversation) async {
    final updatedConversation = await Navigator.pushNamed(
      context,
      AppRouter.thread,
      arguments: conversation,
    );

    if (updatedConversation is Conversation) {
      setState(() {
        final index = _conversations.indexWhere((c) => c.id == updatedConversation.id);
        if (index != -1) {
          _conversations[index] = updatedConversation;
        }
      });
    }
  }

  void _onOpenCompose() async {
    final newConversation = await Navigator.pushNamed(
      context,
      AppRouter.compose,
    );
    if (newConversation is Conversation) {
      setState(() {
        _conversations.insert(0, newConversation);
      });
    }
  }

  void _openProfileSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfileSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = _totalUnreadCount;
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepEspresso,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unreadTotal > 0
                            ? '$unreadTotal unread messages'
                            : 'All caught up',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.chestnut,
                        ),
                      ),
                    ],
                  ),

                  // Profile Button with Avatar
                  InkWell(
                    onTap: _openProfileSettingsSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.deepForest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.celadonStone,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F0F2A1D),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SV',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.softCream,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.greigeStone,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.chestnut,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.deepEspresso,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search messages, contacts, OTPs...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xAA375534),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Tabs
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterTab(
                    label: 'All',
                    isActive: _activeTab == 'all',
                    onTap: () => setState(() => _activeTab = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: unreadTotal > 0 ? 'Unread ($unreadTotal)' : 'Unread',
                    isActive: _activeTab == 'unread',
                    onTap: () => setState(() => _activeTab = 'unread'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Pinned',
                    isActive: _activeTab == 'pinned',
                    onTap: () => setState(() => _activeTab = 'pinned'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'OTP & Alerts',
                    isActive: _activeTab == 'otp',
                    onTap: () => setState(() => _activeTab = 'otp'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Conversation List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'No matching threads',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepEspresso,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try another filter or start a new SMS.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.chestnut,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        return _ConversationTile(
                          conversation: conv,
                          onTap: () => _onOpenThread(conv),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onOpenCompose,
        backgroundColor: AppColors.mossGreen,
        foregroundColor: AppColors.softCream,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),
    );
  }
}

class _ProfileSettingsSheet extends StatefulWidget {
  const _ProfileSettingsSheet();

  @override
  State<_ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<_ProfileSettingsSheet> {
  bool _deliveryReports = true;
  bool _smartOtpClean = true;
  bool _rcsFallback = true;
  final String _soundTone = 'Warm Woodblock';
  final String _bubbleRadius = 'Rounded (20px)';

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.softCream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.warmTaupe.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Top Row: Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile & Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepEspresso,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.greigeStone,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.deepEspresso,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Scrollable Settings Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                // User Profile Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.extraLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.greigeStone, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.deepForest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'SV',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.softCream,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'smsVora Account',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '+91 98765 43210 · SIM 1',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.chestnut,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.greigeStone,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Messaging Preferences Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.extraLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.greigeStone, width: 1),
                  ),
                  child: Column(
                    children: [
                      _ToggleOptionRow(
                        title: 'SMS Delivery Reports',
                        description: 'Show Delivered / Read status under bubbles',
                        value: _deliveryReports,
                        onChanged: (val) {
                          setState(() => _deliveryReports = val);
                        },
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.greigeStone,
                      ),
                      _ToggleOptionRow(
                        title: 'Auto-Organize OTPs',
                        description: 'Group bank & courier codes in OTP tab',
                        value: _smartOtpClean,
                        onChanged: (val) {
                          setState(() => _smartOtpClean = val);
                        },
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.greigeStone,
                      ),
                      _ToggleOptionRow(
                        title: 'RCS to SMS Fallback',
                        description: 'Automatically switch to SMS offline',
                        value: _rcsFallback,
                        onChanged: (val) {
                          setState(() => _rcsFallback = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Sound & Style Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greigeStone,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notification Tone',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEspresso,
                            ),
                          ),
                          Text(
                            _soundTone,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.chestnut,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bubble Geometry',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepEspresso,
                            ),
                          ),
                          Text(
                            _bubbleRadius,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.chestnut,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Other Actions & Full Settings Link
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.settings);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.extraLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.greigeStone, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Advanced Settings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.deepEspresso,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOptionRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleOptionRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEspresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.chestnut,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? AppColors.chestnut : AppColors.warmTaupe,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.softCream,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.deepEspresso : AppColors.greigeStone,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.softCream : AppColors.deepEspresso,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.messages.isNotEmpty
        ? conversation.messages.last
        : null;

    final String previewText = lastMessage != null
        ? (lastMessage.sender == MessageSender.me ? 'You: ' : '') + lastMessage.text
        : '';

    final bool hasUnread = conversation.unread > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: AppColors.greigeStone.withOpacity(0.4),
      highlightColor: AppColors.greigeStone.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: conversation.avatarBgColor,
                  child: Text(
                    conversation.initials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: conversation.avatarTextColor,
                    ),
                  ),
                ),
                if (conversation.pinned)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.warmTaupe,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.softCream, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        size: 9,
                        color: AppColors.deepEspresso,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepEspresso,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.lastTime,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasUnread ? AppColors.chestnut : AppColors.warmTaupe,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                            color: hasUnread ? AppColors.deepEspresso : AppColors.chestnut,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.chestnut,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unread}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.softCream,
                            ),
                          ),
                        ),
                      ],
                    ],
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
