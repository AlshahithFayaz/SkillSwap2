import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography hierarchy using Inter font from Google Fonts.
class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get subheading => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMediumSecondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionBold => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Colors.white,
      );
}
