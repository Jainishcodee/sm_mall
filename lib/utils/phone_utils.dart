String? normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  if (digits.length == 10) {
    return '+91$digits';
  }
  if (digits.length == 12 && digits.startsWith('91')) {
    return '+$digits';
  }
  if (input.trim().startsWith('+') && digits.length >= 10) {
    return '+$digits';
  }
  return null;
}

String last10Digits(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 10) {
    return digits;
  }
  return digits.substring(digits.length - 10);
}

/// Stable, URL-safe identity derived from a phone number. The same number
/// always yields the same key, so it can be used as a Firestore document ID
/// and as the `userId` field on orders/payments. We strip the leading `+` and
/// any non-digit characters so the value is safe to embed in document paths.
///
/// Example: `+91 98765 43210` → `919876543210`.
String phoneKeyFromE164(String e164) {
  return e164.replaceAll(RegExp(r'\D'), '');
}
