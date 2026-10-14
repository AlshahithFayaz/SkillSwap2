import 'package:flutter/material.dart';

/// Semantic color tokens strictly following SkillSwap PRD & UI/UX Pro Max guidelines.
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D9488); // Deep Teal
  static const Color primaryDark = Color(0xFF0F766E); // Teal Dark
  static const Color accent = Color(0xFF06B6D4); // Cyan Accent
  static const Color cyan = Color(0xFF06B6D4);
  static const Color amber = Color(0xFFD97706);
  static const Color teachBadge = Color(0xFF16A34A);

  // Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F766E),
      Color(0xFF0D9488),
      Color(0xFF06B6D4),
    ],
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D9488),
      Color(0xFF06B6D4),
    ],
  );

  // Skill Tokens
  static const Color teach = Color(0xFF16A34A); // Green
  static const Color teachBg = Color(0xFFDCFCE7); // Light green background
  static const Color teachBorder = Color(0xFFBBF7D0);

  static const Color learn = Color(0xFFD97706); // Amber (optimized for 4.5:1 contrast against light backgrounds)
  static const Color learnBg = Color(0xFFFEF3C7); // Light amber background
  static const Color learnBorder = Color(0xFFFDE68A);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Neutral / Surface Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);

  // Text Colors (Accessible Contrast)
  static const Color textPrimary = Color(0xFF0F172A); // High contrast dark slate
  static const Color textSecondary = Color(0xFF475569); // Accessible secondary slate (>= 4.5:1)
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
}
