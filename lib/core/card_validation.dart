/// Card number validation (Luhn) and helpers — same checks as production checkout UIs.
class CardValidation {
  CardValidation._();

  /// Luhn algorithm (ISO/IEC 7812).
  static bool luhnCheck(String digits) {
    if (digits.length < 13 || digits.length > 19) return false;
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String? validateCardNumber(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return 'Enter a valid card number';
    if (!luhnCheck(digits)) return 'Invalid card number';
    return null;
  }

  static String? validateExpiry(String? raw) {
    if (raw == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(raw)) {
      return 'Use MM/YY';
    }
    final parts = raw.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) {
      return 'Invalid expiry';
    }
    final now = DateTime.now();
    final fullYear = 2000 + year;
    final expiryEnd = DateTime(fullYear, month + 1);
    if (expiryEnd.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }
    return null;
  }

  static String? validateCvc(String? raw, {required String cardDigits}) {
    final cvc = raw ?? '';
    if (cvc.length < 3) return 'Enter CVC';
    final brand = detectBrand(cardDigits);
    if (brand == 'amex' && cvc.length != 4) return 'Amex uses 4-digit CVC';
    if (brand != 'amex' && cvc.length < 3) return 'Enter CVC';
    return null;
  }

  static String detectBrand(String digits) {
    if (digits.startsWith('4')) return 'visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits) ||
        RegExp(r'^2[2-7]').hasMatch(digits)) {
      return 'mastercard';
    }
    if (RegExp(r'^3[47]').hasMatch(digits)) return 'amex';
    if (digits.startsWith('6011') || digits.startsWith('65')) return 'discover';
    return 'card';
  }

  static String maskLastFour(String digits) {
    if (digits.length < 4) return '••••';
    return digits.substring(digits.length - 4);
  }
}
