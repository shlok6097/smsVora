class OtpDetectionResult {
  final String code;
  final Duration? expiryDuration;
  final DateTime? expiresAt;
  final bool hasExplicitExpiry;

  const OtpDetectionResult({
    required this.code,
    this.expiryDuration,
    this.expiresAt,
    this.hasExplicitExpiry = false,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get formattedRemaining {
    if (expiresAt == null) {
      return 'Expires soon';
    }
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) {
      return 'Expired';
    }
    final diff = expiresAt!.difference(now);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    if (minutes > 0) {
      return 'Expires in ${minutes}m ${seconds}s';
    } else {
      return 'Expires in ${seconds}s';
    }
  }
}

class OtpDetector {
  OtpDetector._();

  // Pattern matching verification / OTP keywords and numeric codes
  static final RegExp _otpCodeRegex = RegExp(
    r'(?:OTP|code|PIN|secret|verification code|password)\s*(?:is|:|-)?\s*([0-9]{4,8})\b',
    caseSensitive: false,
  );

  static final RegExp _fallbackDigitsRegex = RegExp(
    r'\b([0-9]{4,8})\b',
  );

  // Pattern matching expiry phrases: e.g. "valid for 5 mins", "expires in 10 minutes"
  static final RegExp _expiryRegex = RegExp(
    r'(?:valid\s+(?:for|within)|expires?\s+in|use\s+within)\s*([0-9]{1,3})\s*(mins?|minutes?|secs?|seconds?|hrs?|hours?)',
    caseSensitive: false,
  );

  static final RegExp _validTillTimeRegex = RegExp(
    r'valid\s+till\s+([0-9]{1,2}[:.][0-9]{2})',
    caseSensitive: false,
  );

  static OtpDetectionResult? detect(String text, {DateTime? receivedAt}) {
    final baseTime = receivedAt ?? DateTime.now();

    // 1. Check if the message contains OTP context
    final isOtpContext = text.toLowerCase().contains('otp') ||
        text.toLowerCase().contains('one time password') ||
        text.toLowerCase().contains('verification code') ||
        text.toLowerCase().contains('verification pin') ||
        text.toLowerCase().contains('security code');

    if (!isOtpContext && !text.toLowerCase().contains('code')) {
      return null;
    }

    // 2. Extract code
    String? extractedCode;
    final match = _otpCodeRegex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      extractedCode = match.group(1);
    } else if (isOtpContext) {
      final fallbackMatch = _fallbackDigitsRegex.firstMatch(text);
      if (fallbackMatch != null) {
        extractedCode = fallbackMatch.group(1);
      }
    }

    if (extractedCode == null) return null;

    // 3. Extract expiry duration
    Duration? duration;
    bool hasExplicit = false;

    final expiryMatch = _expiryRegex.firstMatch(text);
    if (expiryMatch != null) {
      final numValue = int.tryParse(expiryMatch.group(1) ?? '');
      final unit = (expiryMatch.group(2) ?? '').toLowerCase();
      if (numValue != null) {
        hasExplicit = true;
        if (unit.startsWith('sec')) {
          duration = Duration(seconds: numValue);
        } else if (unit.startsWith('min')) {
          duration = Duration(minutes: numValue);
        } else if (unit.startsWith('h')) {
          duration = Duration(hours: numValue);
        }
      }
    } else {
      final tillMatch = _validTillTimeRegex.firstMatch(text);
      if (tillMatch != null) {
        hasExplicit = true;
        // Default to a 10-minute fallback for relative till times
        duration = const Duration(minutes: 10);
      }
    }

    // Default to standard 10-minute validity if unspecified
    duration ??= const Duration(minutes: 10);
    final expiresAt = baseTime.add(duration);

    return OtpDetectionResult(
      code: extractedCode,
      expiryDuration: duration,
      expiresAt: expiresAt,
      hasExplicitExpiry: hasExplicit,
    );
  }
}
