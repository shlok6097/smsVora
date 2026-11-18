import 'models/conversation.dart';
import 'models/message.dart';
import 'models/contact.dart';
import '../core/theme/app_colors.dart';

class SampleData {
  SampleData._();

  // ── Quick contacts ──────────────────────────────────────────────────
  static const List<Contact> quickContacts = [
    Contact(name: 'Riya Patel', phone: '+91 98765 43210', initials: 'RP'),
    Contact(name: 'Aman Shah', phone: '+91 87654 32109', initials: 'AS'),
    Contact(name: 'Neha Joshi', phone: '+91 76543 21098', initials: 'NJ'),
    Contact(name: 'Dev Mehta', phone: '+91 65432 10987', initials: 'DM'),
  ];

  // ── Conversations ───────────────────────────────────────────────────
  static final List<Conversation> conversations = [
    // 1. Riya Patel — personal, pinned, 2 unread
    Conversation(
      id: 'conv_1',
      name: 'Riya Patel',
      phone: '+91 98765 43210',
      initials: 'RP',
      avatarBgColor: AppColors.chestnut,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.personal,
      pinned: true,
      unread: 2,
      muted: false,
      lastTime: '10:42 AM',
      carrier: 'Jio',
      messages: const [
        Message(
          id: 'msg_1_1',
          sender: MessageSender.them,
          text: 'Hey, are we still meeting for coffee today?',
          time: '10:30 AM',
          date: 'Today',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_1_2',
          sender: MessageSender.me,
          text: 'Yes! Let us meet at the usual place around 4.',
          time: '10:35 AM',
          date: 'Today',
          status: MessageStatus.delivered,
        ),
        Message(
          id: 'msg_1_3',
          sender: MessageSender.them,
          text: 'Sounds good, see you there!',
          time: '10:40 AM',
          date: 'Today',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_1_4',
          sender: MessageSender.them,
          text: 'Should I bring the notes from yesterday?',
          time: '10:42 AM',
          date: 'Today',
          status: MessageStatus.delivered,
        ),
      ],
    ),

    // 2. Aman Shah — personal
    Conversation(
      id: 'conv_2',
      name: 'Aman Shah',
      phone: '+91 87654 32109',
      initials: 'AS',
      avatarBgColor: AppColors.warmTaupe,
      avatarTextColor: AppColors.deepEspresso,
      category: ConversationCategory.personal,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: '9:15 AM',
      carrier: 'Airtel',
      messages: const [
        Message(
          id: 'msg_2_1',
          sender: MessageSender.me,
          text: 'Did you get the tickets for the match?',
          time: '9:00 AM',
          date: 'Today',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_2_2',
          sender: MessageSender.them,
          text: 'Yes, booked two seats in the east stand.',
          time: '9:10 AM',
          date: 'Today',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_2_3',
          sender: MessageSender.me,
          text: 'Perfect, I will pay you back tonight.',
          time: '9:15 AM',
          date: 'Today',
          status: MessageStatus.delivered,
        ),
      ],
    ),

    // 3. HDFC Bank — OTP, muted
    Conversation(
      id: 'conv_3',
      name: 'HDFC Bank',
      phone: 'HDFCBK',
      initials: 'HB',
      avatarBgColor: AppColors.greigeStone,
      avatarTextColor: AppColors.deepEspresso,
      category: ConversationCategory.otp,
      pinned: false,
      unread: 1,
      muted: true,
      lastTime: 'Yesterday',
      carrier: '',
      messages: const [
        Message(
          id: 'msg_3_1',
          sender: MessageSender.them,
          text:
              'Your OTP for transaction of Rs 2,499 is 847293. Valid for 5 minutes. Do not share with anyone.',
          time: '3:22 PM',
          date: 'Yesterday',
          status: MessageStatus.delivered,
          otp: '847293',
        ),
        Message(
          id: 'msg_3_2',
          sender: MessageSender.them,
          text:
              'Rs 2,499.00 debited from A/c XX1234. UPI Ref 423156789012. If not done by you, call 18002586161.',
          time: '3:25 PM',
          date: 'Yesterday',
          status: MessageStatus.delivered,
        ),
      ],
    ),

    // 4. Neha Joshi — personal
    Conversation(
      id: 'conv_4',
      name: 'Neha Joshi',
      phone: '+91 76543 21098',
      initials: 'NJ',
      avatarBgColor: AppColors.deepEspresso,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.personal,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: 'Yesterday',
      carrier: 'Vi',
      messages: const [
        Message(
          id: 'msg_4_1',
          sender: MessageSender.them,
          text: 'Happy birthday! Hope you have an amazing day!',
          time: '12:01 AM',
          date: 'Yesterday',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_4_2',
          sender: MessageSender.me,
          text: 'Thank you so much, Neha! Means a lot.',
          time: '8:45 AM',
          date: 'Yesterday',
          status: MessageStatus.read,
        ),
      ],
    ),

    // 5. Amazon — OTP
    Conversation(
      id: 'conv_5',
      name: 'Amazon',
      phone: 'AZ-OTP',
      initials: 'AZ',
      avatarBgColor: AppColors.greigeStone,
      avatarTextColor: AppColors.deepEspresso,
      category: ConversationCategory.otp,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: 'Mon',
      carrier: '',
      messages: const [
        Message(
          id: 'msg_5_1',
          sender: MessageSender.them,
          text:
              'Your Amazon OTP is 539104. Do not share this OTP with anyone.',
          time: '2:14 PM',
          date: 'Monday',
          status: MessageStatus.delivered,
          otp: '539104',
        ),
      ],
    ),

    // 6. Dev Mehta — personal, 1 unread
    Conversation(
      id: 'conv_6',
      name: 'Dev Mehta',
      phone: '+91 65432 10987',
      initials: 'DM',
      avatarBgColor: AppColors.chestnut,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.personal,
      pinned: false,
      unread: 1,
      muted: false,
      lastTime: 'Sun',
      carrier: 'BSNL',
      messages: const [
        Message(
          id: 'msg_6_1',
          sender: MessageSender.me,
          text: 'Bro, check out this new restaurant on SG Highway.',
          time: '7:30 PM',
          date: 'Sunday',
          status: MessageStatus.read,
        ),
        Message(
          id: 'msg_6_2',
          sender: MessageSender.them,
          text: 'Which one? Send me the location.',
          time: '7:45 PM',
          date: 'Sunday',
          status: MessageStatus.delivered,
        ),
        Message(
          id: 'msg_6_3',
          sender: MessageSender.me,
          text: 'Sending you the pin now.',
          time: '7:50 PM',
          date: 'Sunday',
          status: MessageStatus.sent,
        ),
        Message(
          id: 'msg_6_4',
          sender: MessageSender.them,
          text: 'Got it. Let us go this Friday?',
          time: '8:00 PM',
          date: 'Sunday',
          status: MessageStatus.delivered,
        ),
      ],
    ),
  ];
}
