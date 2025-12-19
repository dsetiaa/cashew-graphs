import 'package:flutter/material.dart';
import 'app_colours.dart';

class AppTypography {
  // Display - for large headers
  static TextStyle get displayLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.mainTextColor1,
  );

  // Title - for section headers and chart titles
  static TextStyle get titleLarge => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.mainTextColor1,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.mainTextColor1,
  );

  // Body - for general text
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.mainTextColor1,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.mainTextColor2,
  );

  // Label - for axis labels, tooltips, legends
  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.mainTextColor2,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.mainTextColor2,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.mainTextColor3,
  );

  // Chart-specific styles
  static TextStyle get chartTitle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.mainTextColor1,
  );

  static TextStyle get chartAxisLabel => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mainTextColor3,
  );

  static TextStyle get chartTooltipTitle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.mainTextColor1,
  );

  static TextStyle get chartTooltipValue => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mainTextColor1,
  );

  static TextStyle get legendText => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mainTextColor2,
  );
}
