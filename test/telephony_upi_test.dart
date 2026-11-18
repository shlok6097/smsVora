import 'package:flutter_test/flutter_test.dart';
import 'package:smsvora/core/ml/tinybert_service.dart';
import 'package:smsvora/core/services/telephony_service.dart';
import 'package:smsvora/data/models/conversation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TinyBertService.instance.initialize();
  });

  group('TelephonyService & UPI Device Binding Detection', () {
    test('Correctly identifies automated UPI registration SMS by text pattern', () {
      final telephony = TelephonyService.instance;

      expect(
        telephony.isUpiVerificationMessage('UPI 93848201a8f9c2d1e4'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('UPIREG 894012489214'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('BHIM:9823409823094820934'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('PAYTM-BINDING-948201'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('Device binding verification for Google Pay UPI'),
        isTrue,
      );
    });

    test('Correctly identifies UPI registration by recipient gateway number', () {
      final telephony = TelephonyService.instance;

      // Indian UPI SMS verification gateways (NPCI / Banks)
      expect(
        telephony.isUpiVerificationMessage('RandomToken12345', recipient: '9220592205'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('RandomToken12345', recipient: '+91 92205 92205'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('RandomToken12345', recipient: '567676'),
        isTrue,
      );
      expect(
        telephony.isUpiVerificationMessage('RandomToken12345', recipient: '+91 98765 43210'),
        isFalse,
      );
    });

    test('Does not misidentify normal messages as UPI registration', () {
      final telephony = TelephonyService.instance;

      expect(
        telephony.isUpiVerificationMessage('Hey, what are you doing today?'),
        isFalse,
      );
      expect(
        telephony.isUpiVerificationMessage('Your electricity bill of Rs 1,420 is due tomorrow'),
        isFalse,
      );
      expect(
        telephony.isUpiVerificationMessage('URGENT: Your account suspended! Update KYC: http://phish.io'),
        isFalse,
      );
    });

    test('TinyBertService whitelists automated UPI verification and never flags as spam', () {
      final result = TinyBertService.instance.classify(
        messageText: 'UPIREG 9840218490218490214',
        senderHeader: '9220592205',
      );

      expect(result.isScamSuspicious, isFalse);
      expect(result.category, equals(ConversationCategory.banking));
      expect(result.company?.companyName, equals('UPI Device Registration'));
      expect(result.company?.parentFolder, equals('Banking & Finance'));
    });

    test('TinyBertService still flags malicious phishing attempts as spam', () {
      final result = TinyBertService.instance.classify(
        messageText: 'URGENT: Your SBI account suspended! Update PAN immediately: http://bit.ly/update-kyc',
        senderHeader: '+91 98765 43210',
      );

      expect(result.isScamSuspicious, isTrue);
      expect(result.category, equals(ConversationCategory.spam));
    });
  });
}
