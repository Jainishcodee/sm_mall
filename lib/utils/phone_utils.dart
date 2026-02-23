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
