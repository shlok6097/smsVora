import 'package:flutter/material.dart';
import 'models/conversation.dart';
import 'models/message.dart';
import 'models/contact.dart';
import '../core/theme/app_colors.dart';

class SampleData {
  SampleData._();

  // Quick contacts
  static const List<Contact> quickContacts = [
    Contact(name: 'Riya Patel', phone: '+91 98765 43210', initials: 'RP'),
    Contact(name: 'Aman Shah', phone: '+91 87654 32109', initials: 'AS'),
    Contact(name: 'Neha Joshi', phone: '+91 76543 21098', initials: 'NJ'),
    Contact(name: 'Dev Mehta', phone: '+91 65432 10987', initials: 'DM'),
  ];

  // Conversations classified by TinyBERT-4L with sub-folders and spam
  static List<Conversation> get conversations => [
    // 1. Riya Patel — personal, pinned, 2 unread
    const Conversation(
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
      companyName: '',
      companyFolder: '',
      parentFolder: '',
      subFolder: '',
      messages: [
        Message(
          id: 'msg_1_1',
          sender: MessageSender.them,
          text: 'Hey, are we still meeting for coffee today?',
          time: '10:30 AM',
          date: 'Today',
          status: MessageStatus.read,
          category: ConversationCategory.personal,
        ),
        Message(
          id: 'msg_1_2',
          sender: MessageSender.me,
          text: 'Yes! Let us meet at the usual place around 4.',
          time: '10:35 AM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.personal,
        ),
        Message(
          id: 'msg_1_3',
          sender: MessageSender.them,
          text: 'Sounds good, see you there!',
          time: '10:40 AM',
          date: 'Today',
          status: MessageStatus.read,
          category: ConversationCategory.personal,
        ),
        Message(
          id: 'msg_1_4',
          sender: MessageSender.them,
          text: 'Should I bring the notes from yesterday?',
          time: '10:42 AM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.personal,
        ),
      ],
    ),

    // 2. HDFC Bank — Banking & Finance -> Sub-folder: HDFC Bank
    Conversation(
      id: 'conv_2',
      name: 'HDFC Bank',
      phone: 'VM-HDFCBK',
      initials: 'HB',
      avatarBgColor: AppColors.deepForest,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.banking,
      pinned: false,
      unread: 1,
      muted: false,
      lastTime: '8:15 PM',
      carrier: 'Service SMS',
      companyName: 'HDFC Bank',
      companyFolder: 'Banking & Finance',
      parentFolder: 'Banking & Finance',
      subFolder: 'HDFC Bank',
      messages: [
        Message(
          id: 'msg_2_old',
          sender: MessageSender.them,
          text:
              '190482 is your HDFC NetBanking login OTP. Valid for 10 mins. Expired on 16-Nov.',
          time: '10:00 AM',
          date: '16 Nov',
          status: MessageStatus.delivered,
          otp: '190482',
          otpExpiryDuration: const Duration(minutes: 10),
          otpExpiresAt: DateTime.now().subtract(const Duration(hours: 48)),
          category: ConversationCategory.otp,
        ),
        Message(
          id: 'msg_2_1',
          sender: MessageSender.them,
          text:
              '482910 is your One Time Password (OTP) for card ending 4419. Valid for 5 mins. Do not share with anyone.',
          time: '8:15 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          otp: '482910',
          otpExpiryDuration: const Duration(minutes: 5),
          otpExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
          category: ConversationCategory.otp,
        ),
        const Message(
          id: 'msg_2_2',
          sender: MessageSender.them,
          text:
              'Rs 2,499.00 debited from A/c XX1234. UPI Ref 423156789012. If not done by you, call 18002586161.',
          time: '8:16 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.banking,
        ),
      ],
    ),

    // 3. State Bank of India — Banking & Finance -> Sub-folder: State Bank of India (SBI)
    const Conversation(
      id: 'conv_3_sbi',
      name: 'State Bank of India',
      phone: 'AD-SBINB',
      initials: 'SB',
      avatarBgColor: AppColors.deepForest,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.banking,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: '6:30 PM',
      carrier: 'Service SMS',
      companyName: 'State Bank of India',
      companyFolder: 'Banking & Finance',
      parentFolder: 'Banking & Finance',
      subFolder: 'State Bank of India (SBI)',
      messages: [
        Message(
          id: 'msg_sbi_1',
          sender: MessageSender.them,
          text:
              'Dear Customer, your A/c XX8910 has been credited with Rs 45,000.00 on 18-Nov-26 via NEFT. Avail Bal: Rs 1,12,450.00.',
          time: '6:30 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.banking,
        ),
      ],
    ),

    // 4. Amazon — Bills & Deliveries -> Sub-folder: Amazon
    Conversation(
      id: 'conv_3',
      name: 'Amazon',
      phone: 'AX-AMAZON',
      initials: 'AZ',
      avatarBgColor: AppColors.celadonStone,
      avatarTextColor: AppColors.deepForest,
      category: ConversationCategory.deliveries,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: '3:10 PM',
      carrier: 'Service SMS',
      companyName: 'Amazon',
      companyFolder: 'Bills & Deliveries',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Amazon',
      messages: [
        Message(
          id: 'msg_3_1',
          sender: MessageSender.them,
          text:
              'Your Amazon OTP is 539104. Valid for 10 minutes. Do not share this OTP with anyone.',
          time: '3:05 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          otp: '539104',
          otpExpiryDuration: const Duration(minutes: 10),
          otpExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
          category: ConversationCategory.otp,
        ),
        const Message(
          id: 'msg_3_2',
          sender: MessageSender.them,
          text:
              'Your package with order ID 402-8172910 is out for delivery today. Arriving by 7 PM.',
          time: '3:10 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.deliveries,
        ),
      ],
    ),

    // 5. BlueDart Express — Bills & Deliveries -> Sub-folder: BlueDart Express
    Conversation(
      id: 'conv_4',
      name: 'BlueDart Express',
      phone: 'AX-BLUDRT',
      initials: 'BD',
      avatarBgColor: AppColors.mossGreen,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.deliveries,
      pinned: false,
      unread: 0,
      muted: true,
      lastTime: '1:45 PM',
      carrier: 'Service SMS',
      companyName: 'BlueDart Express',
      companyFolder: 'Bills & Deliveries',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'BlueDart Express',
      messages: [
        Message(
          id: 'msg_4_1',
          sender: MessageSender.them,
          text:
              'Your shipment AWB 774920184 is out for delivery. Share PIN 3914 at handover. Valid for 15 mins.',
          time: '1:45 PM',
          date: 'Today',
          status: MessageStatus.delivered,
          otp: '3914',
          otpExpiryDuration: const Duration(minutes: 15),
          otpExpiresAt: DateTime.now().add(const Duration(minutes: 15)),
          category: ConversationCategory.otp,
        ),
      ],
    ),

    // 6. Suspicious Phishing Sender — Spam & Security -> Sub-folder: Phishing / Fake KYC
    const Conversation(
      id: 'conv_spam_1',
      name: 'CP-ALERT (Fake KYC)',
      phone: '+91 99887 76655',
      initials: 'SP',
      avatarBgColor: Color(0xFF8B261E),
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.spam,
      pinned: false,
      unread: 1,
      muted: true,
      lastTime: '11:20 AM',
      carrier: 'Unknown Route',
      companyName: 'Suspicious Sender',
      companyFolder: 'Spam & Security',
      parentFolder: 'Spam & Security',
      subFolder: 'Phishing / Fake KYC',
      isSpam: true,
      spamReason:
          'TinyBERT-4L detected suspicious fake KYC threat and high-risk short URL (bit.ly).',
      messages: [
        Message(
          id: 'msg_spam_1',
          sender: MessageSender.them,
          text:
              'URGENT: Your SBI account suspended today! Update PAN card immediately to avoid permanent block. Click: http://bit.ly/update-sbi-kyc-pan',
          time: '11:20 AM',
          date: 'Today',
          status: MessageStatus.delivered,
          category: ConversationCategory.spam,
        ),
      ],
    ),

    // 7. Aman Shah — personal
    const Conversation(
      id: 'conv_5',
      name: 'Aman Shah',
      phone: '+91 87654 32109',
      initials: 'AS',
      avatarBgColor: AppColors.sageGreen,
      avatarTextColor: AppColors.deepForest,
      category: ConversationCategory.personal,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: '9:15 AM',
      carrier: 'Airtel',
      companyName: '',
      companyFolder: '',
      parentFolder: '',
      subFolder: '',
      messages: [
        Message(
          id: 'msg_5_1',
          sender: MessageSender.me,
          text: 'Did you get the tickets for the match?',
          time: '9:00 AM',
          date: 'Today',
          status: MessageStatus.read,
          category: ConversationCategory.personal,
        ),
        Message(
          id: 'msg_5_2',
          sender: MessageSender.them,
          text: 'Yes, booked two seats in the east stand.',
          time: '9:10 AM',
          date: 'Today',
          status: MessageStatus.read,
          category: ConversationCategory.personal,
        ),
      ],
    ),

    // 8. Neha Joshi — personal
    const Conversation(
      id: 'conv_6',
      name: 'Neha Joshi',
      phone: '+91 76543 21098',
      initials: 'NJ',
      avatarBgColor: AppColors.deepForest,
      avatarTextColor: AppColors.softCream,
      category: ConversationCategory.personal,
      pinned: false,
      unread: 0,
      muted: false,
      lastTime: 'Yesterday',
      carrier: 'Vi',
      companyName: '',
      companyFolder: '',
      parentFolder: '',
      subFolder: '',
      messages: [
        Message(
          id: 'msg_6_1',
          sender: MessageSender.them,
          text: 'Happy birthday! Hope you have an amazing day!',
          time: '12:01 AM',
          date: 'Yesterday',
          status: MessageStatus.read,
          category: ConversationCategory.personal,
        ),
      ],
    ),
  ];
}
