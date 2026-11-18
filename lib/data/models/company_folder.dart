import 'conversation.dart';

class CompanyFolder {
  final String companyName;
  final String categoryName;
  final ConversationCategory category;
  final List<Conversation> conversations;
  final int unreadCount;
  final String lastMessageTime;

  const CompanyFolder({
    required this.companyName,
    required this.categoryName,
    required this.category,
    required this.conversations,
    required this.unreadCount,
    required this.lastMessageTime,
  });
}
