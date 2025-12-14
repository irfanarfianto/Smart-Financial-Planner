import 'package:flutter/material.dart';

class AppColors {
  // Primary Palettes
  static const Color growthGreen = Color(0xFF4CAF50); // Green for Growth
  static const Color ambitiousNavy = Color(0xFF1A237E); // Navy for Ambisius
  static const Color regenerationOrange = Color(
    0xFFEF6C00,
  ); // Orange for Regenerasi

  // Neutral
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Gradient helper
  static LinearGradient getGrowthGradient() => const LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getAmbitiousGradient() => const LinearGradient(
    colors: [Color(0xFF3949AB), Color(0xFF283593)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getRegenerationGradient() => const LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
