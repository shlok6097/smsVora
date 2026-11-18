import '../../data/models/conversation.dart';

class CompanyIdentity {
  final String companyName;
  final String parentFolder;
  final String subFolder;
  final ConversationCategory category;

  const CompanyIdentity({
    required this.companyName,
    required this.parentFolder,
    required this.subFolder,
    required this.category,
  });

  String get folderName => parentFolder;
}

class CompanyExtractor {
  CompanyExtractor._();

  // Known Indian and global SMS sender prefix mappings
  static final Map<String, CompanyIdentity> _knownSenders = {
    // Banking & Finance (Parent Folder) -> Specific Bank Sub-folders
    'NPCI': const CompanyIdentity(
      companyName: 'NPCI UPI Services',
      parentFolder: 'Banking & Finance',
      subFolder: 'UPI & Payments',
      category: ConversationCategory.banking,
    ),
    'BHIM': const CompanyIdentity(
      companyName: 'BHIM UPI',
      parentFolder: 'Banking & Finance',
      subFolder: 'UPI & Payments',
      category: ConversationCategory.banking,
    ),
    'UPI': const CompanyIdentity(
      companyName: 'UPI Verification',
      parentFolder: 'Banking & Finance',
      subFolder: 'UPI & Payments',
      category: ConversationCategory.banking,
    ),
    'HDFCBK': const CompanyIdentity(
      companyName: 'HDFC Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'HDFC Bank',
      category: ConversationCategory.banking,
    ),
    'HDFC': const CompanyIdentity(
      companyName: 'HDFC Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'HDFC Bank',
      category: ConversationCategory.banking,
    ),
    'SBINB': const CompanyIdentity(
      companyName: 'State Bank of India',
      parentFolder: 'Banking & Finance',
      subFolder: 'State Bank of India (SBI)',
      category: ConversationCategory.banking,
    ),
    'SBIINB': const CompanyIdentity(
      companyName: 'State Bank of India',
      parentFolder: 'Banking & Finance',
      subFolder: 'State Bank of India (SBI)',
      category: ConversationCategory.banking,
    ),
    'ICICIB': const CompanyIdentity(
      companyName: 'ICICI Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'ICICI Bank',
      category: ConversationCategory.banking,
    ),
    'AXISBK': const CompanyIdentity(
      companyName: 'Axis Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'Axis Bank',
      category: ConversationCategory.banking,
    ),
    'KOTAKB': const CompanyIdentity(
      companyName: 'Kotak Mahindra Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'Kotak Mahindra Bank',
      category: ConversationCategory.banking,
    ),
    'PNBSMS': const CompanyIdentity(
      companyName: 'Punjab National Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'Punjab National Bank',
      category: ConversationCategory.banking,
    ),
    'PAYTM': const CompanyIdentity(
      companyName: 'Paytm Payments Bank',
      parentFolder: 'Banking & Finance',
      subFolder: 'Paytm Payments Bank',
      category: ConversationCategory.banking,
    ),

    // Deliveries & E-Commerce (Parent Folder) -> Specific Company Sub-folders
    'AMAZON': const CompanyIdentity(
      companyName: 'Amazon',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Amazon',
      category: ConversationCategory.deliveries,
    ),
    'AMZN': const CompanyIdentity(
      companyName: 'Amazon',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Amazon',
      category: ConversationCategory.deliveries,
    ),
    'FLIPKT': const CompanyIdentity(
      companyName: 'Flipkart',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Flipkart',
      category: ConversationCategory.deliveries,
    ),
    'BLUDRT': const CompanyIdentity(
      companyName: 'BlueDart Express',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'BlueDart Express',
      category: ConversationCategory.deliveries,
    ),
    'DLHVRY': const CompanyIdentity(
      companyName: 'Delhivery Logistics',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Delhivery',
      category: ConversationCategory.deliveries,
    ),
    'SWIGGY': const CompanyIdentity(
      companyName: 'Swiggy',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Swiggy Food',
      category: ConversationCategory.deliveries,
    ),
    'ZOMATO': const CompanyIdentity(
      companyName: 'Zomato',
      parentFolder: 'Bills & Deliveries',
      subFolder: 'Zomato Delivery',
      category: ConversationCategory.deliveries,
    ),

    // Telecom (Parent Folder) -> Specific Provider Sub-folders
    'JIO': const CompanyIdentity(
      companyName: 'Jio Services',
      parentFolder: 'Telecom & Services',
      subFolder: 'Jio Fiber & Mobile',
      category: ConversationCategory.actions,
    ),
    'AIRTEL': const CompanyIdentity(
      companyName: 'Airtel Telephony',
      parentFolder: 'Telecom & Services',
      subFolder: 'Airtel Telecom',
      category: ConversationCategory.actions,
    ),
    'VIL': const CompanyIdentity(
      companyName: 'Vodafone Idea',
      parentFolder: 'Telecom & Services',
      subFolder: 'Vodafone Idea (Vi)',
      category: ConversationCategory.actions,
    ),
    'BSNL': const CompanyIdentity(
      companyName: 'BSNL Telecom',
      parentFolder: 'Telecom & Services',
      subFolder: 'BSNL Mobile',
      category: ConversationCategory.actions,
    ),
  };

  /// Extracts or automatically generates the Principal Entity / Brand and folder hierarchy.
  /// Handles standard Indian headers like "VM-HDFCBK", "AX-BLUDRT", "AD-AMAZON", as well as
  /// dynamic/unknown corporate headers like "VK-CANBNK", "BZ-UBER", etc.
  static CompanyIdentity? extract(
    String senderHeader, [
    String? messageBody,
    ConversationCategory? predictedCategory,
  ]) {
    final cleanHeader = senderHeader.trim().toUpperCase();

    // 1. Direct key match
    if (_knownSenders.containsKey(cleanHeader)) {
      return _knownSenders[cleanHeader];
    }

    // 2. Parse TRAI 2-letter operator prefix + hyphen + entity code
    String? entityPart;
    if (cleanHeader.contains('-')) {
      final parts = cleanHeader.split('-');
      if (parts.length >= 2) {
        entityPart = parts[1].trim();
        for (final entry in _knownSenders.entries) {
          if (entityPart.contains(entry.key) || entry.key.contains(entityPart)) {
            return entry.value;
          }
        }
      }
    }

    // 3. Substring matching against known keys
    for (final entry in _knownSenders.entries) {
      if (cleanHeader.contains(entry.key)) {
        return entry.value;
      }
    }

    // 4. Fallback search inside message body for brand confirmation
    if (messageBody != null && messageBody.isNotEmpty) {
      final upperBody = messageBody.toUpperCase();
      for (final entry in _knownSenders.entries) {
        if (upperBody.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // 5. Automatic Dynamic Folder Generation for unknown business/service senders:
    // If the sender is an alphanumeric header (not a plain phone number) or classified by TinyBERT
    final isAlphanumericHeader = RegExp(r'[A-Za-z]').hasMatch(cleanHeader);
    if (isAlphanumericHeader) {
      final rawName =
          entityPart ?? cleanHeader.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (rawName.isNotEmpty && rawName.length >= 3) {
        // Banking & Finance heuristic or TinyBERT classification
        final isBanking = predictedCategory == ConversationCategory.banking ||
            rawName.contains('BK') ||
            rawName.contains('BNK') ||
            rawName.contains('BANK') ||
            rawName.contains('FIN') ||
            rawName.contains('PAY') ||
            (messageBody != null &&
                RegExp(r'(A/C|DEBITED|CREDITED|INR|RS\.|NEFT|IMPS|UPI)',
                        caseSensitive: false)
                    .hasMatch(messageBody));

        if (isBanking) {
          final bankName = rawName.endsWith('BK') ||
                  rawName.endsWith('BNK') ||
                  rawName.endsWith('BANK')
              ? rawName
              : '$rawName Bank';
          return CompanyIdentity(
            companyName: bankName,
            parentFolder: 'Banking & Finance',
            subFolder: bankName,
            category: ConversationCategory.banking,
          );
        }

        // Deliveries heuristic or TinyBERT classification
        final isDelivery = predictedCategory ==
                ConversationCategory.deliveries ||
            rawName.contains('EXP') ||
            rawName.contains('DLV') ||
            rawName.contains('POST') ||
            rawName.contains('COURIER') ||
            (messageBody != null &&
                RegExp(r'(ORDER|SHIPMENT|DISPATCHED|OUT FOR DELIVERY|TRACKING|AWB)',
                        caseSensitive: false)
                    .hasMatch(messageBody));

        if (isDelivery) {
          return CompanyIdentity(
            companyName: rawName,
            parentFolder: 'Bills & Deliveries',
            subFolder: rawName,
            category: ConversationCategory.deliveries,
          );
        }

        // General business/service folder
        return CompanyIdentity(
          companyName: rawName,
          parentFolder: 'Services & Subscriptions',
          subFolder: rawName,
          category: predictedCategory ?? ConversationCategory.actions,
        );
      }
    }

    return null;
  }
}
