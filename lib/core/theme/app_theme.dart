import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const Color pulseOrange = Color(0xFFFF6A00);
  static const Color brightOrange = Color(0xFFFF8E33);
  static const Color softAmber = Color(0xFFFFC17A);

  // Neutral
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color warmWhite = Color(0xFFFFF2E5);
  static const Color lightGray = Color(0xFFF5F6F8);

  // Dark
  static const Color charcoalBlack = Color(0xFF121212);
  static const Color slateGray = Color(0xFF6B7280);

  // Gradient
  static const Color gradientStart = Color(0xFFFF6A00);
  static const Color gradientEnd = Color(0xFFFFB347);

  // Semantic aliases
  static const Color primaryButton = pulseOrange;
  static const Color hoverState = brightOrange;
  static const Color background = pureWhite;
  static const Color cardBackground = warmWhite;
  static const Color textPrimary = charcoalBlack;
  static const Color textSecondary = slateGray;
  static const Color iconsOnOrange = pureWhite;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pulseOrange,
          primary: AppColors.pulseOrange,
          secondary: AppColors.brightOrange,
          surface: AppColors.pureWhite,
          onPrimary: AppColors.iconsOnOrange,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.cardBackground,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
        ),
      );
}
