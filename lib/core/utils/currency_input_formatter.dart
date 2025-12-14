import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If empty, return consistent
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Clean all non-digit characters
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // If result is empty after cleaning (e.g. user typed only letters)
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse numeric value
    final double value = double.parse(cleanText);

    // Format proper string
    final String newText = _formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
