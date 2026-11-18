import 'package:flutter/services.dart';

class TelephonyService {
  TelephonyService._();
  static final TelephonyService instance = TelephonyService._();

  static const MethodChannel _channel = MethodChannel('smsvora/telephony');

  // Known NPCI / Bank automated UPI device binding gateways in India
  static final Set<String> knownUpiGateways = {
    '9220592205',
    '9215692156',
    '567676',
    '8082800000',
    '9870800000',
    '57575',
    '56161',
  };

  /// Whether automated UPI device registration messages are allowed and whitelisted.
  bool allowAutomatedUpi = true;

  /// Checks if smsVora is currently the device's Default SMS Application.
  Future<bool> isDefaultSmsApp() async {
    try {
      final bool? isDefault =
          await _channel.invokeMethod<bool>('isDefaultSmsApp');
      return isDefault ?? false;
    } catch (_) {
      // In non-Android or testing environments
      return true;
    }
  }

  /// Prompts the Android system dialog to set smsVora as the Default SMS Application.
  Future<bool> requestDefaultSmsApp() async {
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('requestDefaultSmsApp');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sends an SMS directly via native Android SmsManager, supporting SIM slot (subId).
  Future<bool> sendSms({
    required String phone,
    required String message,
    int? subId,
  }) async {
    try {
      final Map<String, dynamic> args = {
        'phone': phone,
        'message': message,
      };
      if (subId != null) {
        args['subId'] = subId;
      }
      final bool? success = await _channel.invokeMethod<bool>('sendSms', args);
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Detects whether an outgoing or incoming SMS is an automated UPI device binding verification SMS.
  bool isUpiVerificationMessage(String text, {String? recipient}) {
    if (recipient != null) {
      String cleanRecipient = recipient.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanRecipient.startsWith('91') && cleanRecipient.length == 12) {
        cleanRecipient = cleanRecipient.substring(2);
      }
      if (knownUpiGateways.contains(cleanRecipient) ||
          knownUpiGateways.contains(recipient.replaceAll(RegExp(r'[^0-9]'), ''))) {
        return true;
      }
    }

    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();

    // Common UPI device binding patterns:
    // e.g., "UPI <token>", "UPIREG <hash>", "BHIM <device_token>", "//UPI", "PAYTM <token>"
    final upiPattern = RegExp(
      r'^(?:UPI|UPIREG|BHIM|NPCI|PAYTM|GPAY|PHONEPE|CRED)(?:\s+|[:\-/])([a-zA-Z0-9_\-]+)',
      caseSensitive: false,
    );

    if (upiPattern.hasMatch(trimmed)) {
      return true;
    }

    if (lower.contains('device binding') ||
        lower.contains('upi registration') ||
        lower.contains('verify mobile banking') ||
        lower.contains('sim verification for upi')) {
      return true;
    }

    return false;
  }
}
