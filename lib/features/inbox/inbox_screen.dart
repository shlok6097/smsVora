import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ml/otp_detector.dart';
import '../../core/ml/tinybert_service.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/app_settings.dart';
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
  Timer? _countdownTimer;

  // Folder drill-down state
  String? _openedFolderName;
  List<Conversation>? _openedFolderConversations;

  Message? _findMostRecentMessageInFolder(List<Conversation> conversations) {
    Message? recent;
    for (final c in conversations) {
      if (c.messages.isNotEmpty) {
        final last = c.messages.last;
        if (recent == null || last.sortTimestamp.isAfter(recent.sortTimestamp)) {
          recent = last;
        }
      }
    }
    return recent;
  }

  String? _findCopyableValueForMessage(Message msg) {
    if (msg.otp != null && msg.otp!.trim().isNotEmpty) {
      return msg.otp!.trim();
    }
    final detected = OtpDetector.detect(msg.text);
    if (detected != null && detected.code.trim().isNotEmpty) {
      return detected.code.trim();
    }
    final numMatch = RegExp(r'\b\d{4,12}\b').firstMatch(msg.text);
    if (numMatch != null) {
      return numMatch.group(0);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _conversations = List.from(SampleData.conversations);
    AppSettings.instance.cleanExpiredOtps(_conversations);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        if (AppSettings.instance.deleteExpiredOtps) {
          final cleaned = AppSettings.instance.cleanExpiredOtps(_conversations);
          if (cleaned > 0) {
            setState(() {});
            return;
          }
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int get _totalUnreadCount {
    return _conversations.fold(0, (sum, c) => sum + (c.isSpam ? 0 : c.unread));
  }

  int get _spamCount {
    return _conversations.where((c) => c.isSpam).length;
  }

  List<Conversation> get _filteredConversations {
    return _conversations.where((c) {
      if (_activeTab == 'spam') {
        if (!c.isSpam) return false;
      } else {
        if (c.isSpam) return false;
      }

      if (_activeTab == 'unread' && c.unread == 0) return false;
      if (_activeTab == 'pinned' && !c.pinned) return false;
      if (_activeTab == 'otp') {
        final hasOtp = c.category == ConversationCategory.otp ||
            c.messages.any((m) => m.otp != null);
        if (!hasOtp) return false;
      }
      if (_activeTab == 'companies') {
        if (c.companyName.isEmpty && c.parentFolder.isEmpty) return false;
      }
      if (_activeTab == 'banking' && c.category != ConversationCategory.banking) {
        return false;
      }
      if (_activeTab == 'deliveries' && c.category != ConversationCategory.deliveries) {
        return false;
      }
      if (_activeTab == 'personal' && c.category != ConversationCategory.personal) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesPhone = c.phone.toLowerCase().contains(query);
        final matchesCompany = c.companyName.toLowerCase().contains(query);
        final matchesSub = c.subFolder.toLowerCase().contains(query);
        final matchesParent = c.parentFolder.toLowerCase().contains(query);
        final matchesMsg = c.messages.any((m) => m.text.toLowerCase().contains(query));
        return matchesName ||
            matchesPhone ||
            matchesCompany ||
            matchesSub ||
            matchesParent ||
            matchesMsg;
      }
      return true;
    }).toList();
  }

  Map<String, Map<String, List<Conversation>>> get _hierarchicalCompanyFolders {
    final Map<String, Map<String, List<Conversation>>> hierarchy = {};
    for (final c in _conversations) {
      if (c.isSpam) continue;
      if (c.companyName.isNotEmpty || c.parentFolder.isNotEmpty) {
        final parent = c.parentFolder.isNotEmpty ? c.parentFolder : 'Other Organizations';
        final sub = c.subFolder.isNotEmpty
            ? c.subFolder
            : (c.companyName.isNotEmpty ? c.companyName : 'General');
        hierarchy.putIfAbsent(parent, () => {}).putIfAbsent(sub, () => []).add(c);
      }
    }
    return hierarchy;
  }

  void _onMarkNotSpam(Conversation conv) {
    setState(() {
      final index = _conversations.indexWhere((c) => c.id == conv.id);
      if (index != -1) {
        _conversations[index] = conv.copyWith(
          isSpam: false,
          category: ConversationCategory.personal,
          spamReason: '',
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${conv.name} restored to regular inbox'),
        backgroundColor: AppColors.deepForest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDeleteConversation(Conversation conv) {
    setState(() {
      _conversations.removeWhere((c) => c.id == conv.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thread deleted permanently'),
        backgroundColor: AppColors.chestnut,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      builder: (context) => _ProfileSettingsSheet(
        onTriggerClean: () {
          final count = AppSettings.instance.cleanExpiredOtps(_conversations);
          if (count > 0 && mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = _totalUnreadCount;
    final spamTotal = _spamCount;
    final filtered = _filteredConversations;
    final hierarchicalFolders = _hierarchicalCompanyFolders;

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
                      Row(
                        children: [
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.greigeStone,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TinyBERT-4L Active',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                          ),
                        ],
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
                          hintText: 'Search messages, companies, OTPs...',
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

            // Filter Tabs (Categorization via TinyBERT-4L)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterTab(
                    label: 'All',
                    isActive: _activeTab == 'all',
                    onTap: () => setState(() {
                      _activeTab = 'all';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Company Folders',
                    isActive: _activeTab == 'companies',
                    onTap: () => setState(() {
                      _activeTab = 'companies';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: spamTotal > 0 ? 'Spam ($spamTotal)' : 'Spam',
                    isActive: _activeTab == 'spam',
                    isWarning: spamTotal > 0,
                    onTap: () => setState(() {
                      _activeTab = 'spam';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: unreadTotal > 0 ? 'Unread ($unreadTotal)' : 'Unread',
                    isActive: _activeTab == 'unread',
                    onTap: () => setState(() {
                      _activeTab = 'unread';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'OTP & Alerts',
                    isActive: _activeTab == 'otp',
                    onTap: () => setState(() {
                      _activeTab = 'otp';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Banking',
                    isActive: _activeTab == 'banking',
                    onTap: () => setState(() {
                      _activeTab = 'banking';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Deliveries',
                    isActive: _activeTab == 'deliveries',
                    onTap: () => setState(() {
                      _activeTab = 'deliveries';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: 'Personal',
                    isActive: _activeTab == 'personal',
                    onTap: () => setState(() {
                      _activeTab = 'personal';
                      _openedFolderName = null;
                      _openedFolderConversations = null;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Conversation / Company Folders / Spam View
            Expanded(
              child: _activeTab == 'companies'
                  ? (_openedFolderName != null &&
                          _openedFolderConversations != null
                      ? _buildFolderDetailView(
                          _openedFolderName!,
                          _openedFolderConversations!,
                        )
                      : _buildHierarchicalCompanyFoldersView(
                          hierarchicalFolders,
                        ))
                  : (_activeTab == 'spam'
                      ? _buildSpamView(filtered)
                      : (filtered.isEmpty
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
                            ))),
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

  Widget _buildHierarchicalCompanyFoldersView(
      Map<String, Map<String, List<Conversation>>> folders) {
    if (folders.isEmpty) {
      return const Center(
        child: Text(
          'No company folders detected yet.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.chestnut,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Informational header
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.greigeStone.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.greigeStone, width: 1),
          ),
          child: Row(
            children: const [
              Icon(Icons.folder_copy_outlined, size: 18, color: AppColors.deepForest),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Parent categories and merchant sub-folders classified by TinyBERT-4L on-device NLP.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepForest,
                  ),
                ),
              ),
            ],
          ),
        ),

        ...folders.entries.map((parentEntry) {
          final parentName = parentEntry.key;
          final subFolders = parentEntry.value;
          final totalConvs =
              subFolders.values.fold(0, (sum, list) => sum + list.length);

          IconData parentIcon = Icons.business_rounded;
          if (parentName.contains('Bank') || parentName.contains('Finance')) {
            parentIcon = Icons.account_balance_rounded;
          } else if (parentName.contains('Deliver') ||
              parentName.contains('Bill')) {
            parentIcon = Icons.local_shipping_rounded;
          } else if (parentName.contains('Telecom')) {
            parentIcon = Icons.cell_tower_rounded;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.extraLight,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.greigeStone, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parent Folder Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.deepForest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          parentIcon,
                          size: 19,
                          color: AppColors.softCream,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parentName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepForest,
                              ),
                            ),
                            Text(
                              '${subFolders.length} Sub-folders · $totalConvs Conversations',
                              style: const TextStyle(
                                fontSize: 11,
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
                const Divider(
                    height: 1, thickness: 1, color: AppColors.greigeStone),

                // Sub-folders: Show ONLY the most recent message; tap to open all messages
                ...subFolders.entries.map((subEntry) {
                  final subName = subEntry.key;
                  final conversations = subEntry.value;
                  final recentMsg =
                      _findMostRecentMessageInFolder(conversations);
                  final totalMessages = conversations.fold(
                      0, (sum, c) => sum + c.messages.length);
                  final copyableCode = recentMsg != null
                      ? _findCopyableValueForMessage(recentMsg)
                      : null;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _openedFolderName = subName;
                          _openedFolderConversations = conversations;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.greigeStone.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Folder Title & Count Header
                            Row(
                              children: [
                                const Icon(
                                  Icons.folder_rounded,
                                  size: 18,
                                  color: AppColors.mossGreen,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    subName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.deepEspresso,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greigeStone,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$totalMessages ${totalMessages == 1 ? 'msg' : 'msgs'}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.deepEspresso,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppColors.chestnut,
                                ),
                              ],
                            ),

                            // Recent Message Only
                            if (recentMsg != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.extraLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AppColors.greigeStone.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Recent · ${recentMsg.date} ${recentMsg.time}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.chestnut,
                                          ),
                                        ),
                                        if (copyableCode != null)
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: copyableCode));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      recentMsg.otp != null
                                                          ? 'OTP $copyableCode copied to clipboard'
                                                          : 'Copied $copyableCode to clipboard',
                                                    ),
                                                    backgroundColor:
                                                        AppColors.deepForest,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.greigeStone,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .content_copy_rounded,
                                                      size: 10,
                                                      color:
                                                          AppColors.deepForest,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      copyableCode,
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: AppColors
                                                            .deepForest,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recentMsg.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.3,
                                        color: AppColors.deepEspresso,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFolderDetailView(
      String folderName, List<Conversation> conversations) {
    final List<_FolderMessageEntry> allEntries = [];
    for (final c in conversations) {
      for (final m in c.messages) {
        allEntries.add(_FolderMessageEntry(message: m, conversation: c));
      }
    }

    // Sort all messages chronologically by date and time in descending order (most recent first)
    allEntries.sort((a, b) =>
        b.message.sortTimestamp.compareTo(a.message.sortTimestamp));

    return Column(
      children: [
        // Navigation bar with Back to Folders button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() {
                  _openedFolderName = null;
                  _openedFolderConversations = null;
                }),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greigeStone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.arrow_back_ios_new_rounded,
                          size: 13, color: AppColors.deepForest),
                      SizedBox(width: 4),
                      Text(
                        'Folders',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepForest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folderName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepEspresso,
                      ),
                    ),
                    Text(
                      '${allEntries.length} Messages · Sorted by Date & Time',
                      style: const TextStyle(
                        fontSize: 11,
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

        // List of all messages sorted chronologically
        Expanded(
          child: allEntries.isEmpty
              ? const Center(
                  child: Text(
                    'No messages in this folder.',
                    style: TextStyle(color: AppColors.chestnut),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: allEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = allEntries[index];
                    final msg = item.message;
                    final conv = item.conversation;
                    final copyableCode = _findCopyableValueForMessage(msg);
                    final isOtp = msg.otp != null ||
                        OtpDetector.detect(msg.text) != null;

                    return InkWell(
                      onTap: () => _onOpenThread(conv),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.extraLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.greigeStone,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Sender Avatar & Date / Time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: conv.avatarBgColor,
                                      child: Text(
                                        conv.initials,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: conv.avatarTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      conv.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepForest,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greigeStone,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${msg.date} · ${msg.time}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.deepEspresso,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Message Content
                            Text(
                              msg.text,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                            if (copyableCode != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: copyableCode));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isOtp
                                                  ? 'OTP $copyableCode copied to clipboard'
                                                  : 'Copied $copyableCode to clipboard',
                                            ),
                                            backgroundColor:
                                                AppColors.deepForest,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.greigeStone,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.warmTaupe
                                                .withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.content_copy_rounded,
                                              size: 11,
                                              color: AppColors.deepForest,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              copyableCode,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.deepForest,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSpamView(List<Conversation> spamList) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Spam Security Alert Header
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x188B261E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x448B261E), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B261E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.softCream,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TinyBERT-4L Spam & Phishing Shield',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B261E),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Suspicious senders, fake KYC requests, and high-risk links are isolated locally on-device to prevent credential theft.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.deepEspresso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (spamList.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: const [
                Icon(
                  Icons.verified_user_rounded,
                  size: 44,
                  color: AppColors.mossGreen,
                ),
                SizedBox(height: 12),
                Text(
                  'Spam folder is clean',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEspresso,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No phishing or scam threats detected in your SMS.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.chestnut,
                  ),
                ),
              ],
            ),
          )
        else
          ...spamList.map((conv) {
            final lastMsg =
                conv.messages.isNotEmpty ? conv.messages.last : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.extraLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x338B261E), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _onOpenThread(conv),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF8B261E),
                                child: Text(
                                  conv.initials,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
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
                                      conv.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.deepEspresso,
                                      ),
                                    ),
                                    Text(
                                      conv.phone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.chestnut,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B261E),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'BLOCKED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.softCream,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (conv.spamReason != null && conv.spamReason!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x188B261E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: Color(0xFF8B261E),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      conv.spamReason!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF8B261E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (lastMsg != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              lastMsg.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.greigeStone),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _onMarkNotSpam(conv),
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 15),
                          label: const Text('Not Spam',
                              style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.deepForest,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _onDeleteConversation(conv),
                          icon:
                              const Icon(Icons.delete_outline_rounded, size: 15),
                          label: const Text('Delete',
                              style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF8B261E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ProfileSettingsSheet extends StatefulWidget {
  final VoidCallback? onTriggerClean;
  const _ProfileSettingsSheet({this.onTriggerClean});

  @override
  State<_ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<_ProfileSettingsSheet> {
  bool _deliveryReports = AppSettings.instance.deliveryReports;
  bool _smartOtpClean = AppSettings.instance.autoOrganizeOtps;
  bool _rcsFallback = AppSettings.instance.rcsFallback;
  bool _deleteExpiredOtps = AppSettings.instance.deleteExpiredOtps;
  final String _soundTone = AppSettings.instance.soundTone;
  final String _bubbleRadius = AppSettings.instance.bubbleRadius;

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

                // TinyBERT-4L Engine Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.extraLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.greigeStone, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TinyBERT-4L On-Device AI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepForest,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mossGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '24.8 MB',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.softCream,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Classifies SMS into Personal, Banking, Deliveries & Actions. Detects OTP expiry countdowns and groups company folders 100% locally on CPU without external servers.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.chestnut,
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
                          AppSettings.instance.rcsFallback = val;
                        },
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.greigeStone,
                      ),
                      _ToggleOptionRow(
                        title: 'Delete Expired OTPs',
                        description:
                            'Automatically delete expired OTP messages after 24 hours',
                        value: _deleteExpiredOtps,
                        onChanged: (val) {
                          setState(() {
                            _deleteExpiredOtps = val;
                            AppSettings.instance.deleteExpiredOtps = val;
                          });
                          if (val) {
                            widget.onTriggerClean?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Auto-cleanup active: expired OTPs will delete after 24h.'),
                                backgroundColor: AppColors.deepForest,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
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
  final bool isWarning;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isActive,
    this.isWarning = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (isActive) {
      bg = isWarning ? const Color(0xFF8B261E) : AppColors.deepEspresso;
      fg = AppColors.softCream;
    } else {
      bg = isWarning ? const Color(0x288B261E) : AppColors.greigeStone;
      fg = isWarning ? const Color(0xFF8B261E) : AppColors.deepEspresso;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
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

  String? _findCopyableValue(Conversation conv) {
    // 1. Prioritize active/unexpired OTP in the conversation (latest to oldest)
    for (int i = conv.messages.length - 1; i >= 0; i--) {
      final m = conv.messages[i];
      if (m.otp != null && m.otp!.trim().isNotEmpty && !m.isOtpExpired) {
        return m.otp!.trim();
      }
    }
    // 2. Check latest message for explicit OTP or detected OTP
    final lastMsg = conv.messages.isNotEmpty ? conv.messages.last : null;
    if (lastMsg != null) {
      if (lastMsg.otp != null && lastMsg.otp!.trim().isNotEmpty) {
        return lastMsg.otp!.trim();
      }
      final detected = OtpDetector.detect(lastMsg.text);
      if (detected != null && detected.code.trim().isNotEmpty) {
        return detected.code.trim();
      }
      // 3. Fallback to number / code in latest message (4 to 12 digits)
      final numMatch = RegExp(r'\b\d{4,12}\b').firstMatch(lastMsg.text);
      if (numMatch != null) {
        return numMatch.group(0);
      }
    }
    return null;
  }

  Message? _findMessageForValue(Conversation conv, String value) {
    for (int i = conv.messages.length - 1; i >= 0; i--) {
      final m = conv.messages[i];
      if (m.otp == value || m.text.contains(value)) {
        return m;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.messages.isNotEmpty
        ? conversation.messages.last
        : null;

    final String previewText = lastMessage != null
        ? (lastMessage.sender == MessageSender.me ? 'You: ' : '') + lastMessage.text
        : '';

    final bool hasUnread = conversation.unread > 0;
    final bool hasOtp = lastMessage?.otp != null;
    final String? copyableCode = _findCopyableValue(conversation);
    final Message? codeMessage = copyableCode != null
        ? _findMessageForValue(conversation, copyableCode)
        : null;
    final bool isOtp = codeMessage?.otp == copyableCode ||
        (codeMessage != null &&
            OtpDetector.detect(codeMessage.text)?.code == copyableCode);

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
                        child: Row(
                          children: [
                            Flexible(
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
                            if (conversation.companyName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.greigeStone,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  conversation.companyFolder.isNotEmpty
                                      ? conversation.companyFolder.split(' ')[0]
                                      : 'Brand',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                      if (copyableCode != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: copyableCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isOtp
                                        ? 'OTP $copyableCode copied to clipboard'
                                        : 'Copied $copyableCode to clipboard',
                                  ),
                                  backgroundColor: AppColors.deepForest,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.greigeStone,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warmTaupe.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.content_copy_rounded,
                                    size: 11,
                                    color: AppColors.deepForest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    copyableCode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.deepForest,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _FolderMessageEntry {
  final Message message;
  final Conversation conversation;

  const _FolderMessageEntry({
    required this.message,
    required this.conversation,
  });
}
