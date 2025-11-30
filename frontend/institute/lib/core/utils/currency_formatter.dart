import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Nepali Rupee formatter with comma separation
  static String formatNPR(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return 'Rs. ${formatter.format(amount)}';
  }

  // Format without decimal places for whole numbers
  static String formatNPRCompact(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return 'Rs. ${formatter.format(amount)}';
  }

  // Format with custom decimal places
  static String formatNPRWithDecimals(double amount, int decimalPlaces) {
    final pattern = decimalPlaces > 0
        ? '#,##,##0.${"0" * decimalPlaces}'
        : '#,##,##0';
    final formatter = NumberFormat(pattern, 'en_IN');
    return 'Rs. ${formatter.format(amount)}';
  }

  // Parse string to double
  static double parseAmount(String amount) {
    // Remove Rs., commas, and whitespace
    final cleaned = amount.replaceAll(RegExp(r'[Rs.,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
