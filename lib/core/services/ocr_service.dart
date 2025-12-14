import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  final double? amount;
  final DateTime? date;
  final String? merchantName;

  OcrResult({this.amount, this.date, this.merchantName});
}

class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<File?> pickImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickImageFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    return _parseReceiptText(recognizedText);
  }

  OcrResult _parseReceiptText(RecognizedText recognizedText) {
    String text = recognizedText.text;
    List<String> lines = text.split('\n');

    double? totalAmount;
    DateTime? date;
    String? merchant;

    // 1. Try to find Merchant Name (Usually the first non-empty line)
    // Simple heuristic: Take the first line that looks like a name
    for (var line in lines) {
      if (line.trim().isNotEmpty && line.length > 3) {
        merchant = line.trim();
        break;
      }
    }

    // 2. Try to find Total Amount
    // Regex to find currency-like patterns (e.g., 50.000, 50,000, Rp 50.000)
    // We look for the largest number assuming it's the total.
    // Also look for keywords like "Total", "Jumlah", "Grand Total" near a number.

    // Cleaning text for easier parsing
    // Standardize: Remove 'Rp', '.', ',' based on locale logic (IDR/USD)
    // Complexity: Thousands separator vs Decimal separator
    // Assumption for IDR: dot (.) is thousands, comma (,) is decimal

    List<double> foundNumbers = [];
    final numberRegex = RegExp(r'[0-9]+[.,]?[0-9]*[.,]?[0-9]*');

    for (var line in lines) {
      // Find numbers in line
      Iterable<Match> matches = numberRegex.allMatches(line);
      for (var match in matches) {
        String numStr = match.group(0)!;

        // Let's assume Indonesia Format primarily: 10.000 -> 10000
        String idrClean = numStr.replaceAll(
          '.',
          '',
        ); // Remove thousands (10.000 -> 10000)
        idrClean = idrClean.replaceAll(
          ',',
          '.',
        ); // Change decimal comma to dot (10,50 -> 10.50)

        try {
          double val = double.parse(idrClean);
          // Filter unlikely amounts (e.g. phone numbers, dates misread as numbers)
          if (val > 100 && val < 500000000) {
            // Valid range assumption
            foundNumbers.add(val);
          }
        } catch (e) {
          // ignore
        }
      }
    }

    if (foundNumbers.isNotEmpty) {
      // Heuristic: Total is usually the MAX number found on a receipt
      // Or finding keyword "Total" line
      // Let's grab the MAX for simplicity first
      foundNumbers.sort(); // ascending
      totalAmount = foundNumbers.last;
    }

    // 3. Try to find Date
    // Regex for DD/MM/YYYY or YYYY-MM-DD or DD-MM-YYYY
    final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');
    final matchDate = dateRegex.firstMatch(text);
    if (matchDate != null) {
      try {
        // Naive parsing, assuming DD/MM/YYYY
        int d = int.parse(matchDate.group(1)!);
        int m = int.parse(matchDate.group(2)!);
        int y = int.parse(matchDate.group(3)!);

        if (y < 100) y += 2000; // 24 -> 2024

        date = DateTime(y, m, d);
      } catch (e) {
        // ignore
      }
    }

    return OcrResult(amount: totalAmount, date: date, merchantName: merchant);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
