import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== Primary =====
  static const Color primary = Color(0xFFFF2D4D);
  static const Color primaryHover = Color(0xFFE62342);

  // ===== Background =====
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF8F8F8);

  // ===== Surface =====
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ===== Border =====
  static const Color border = Color(0xFFE5E5E5);

  // ===== Placeholder =====
  static const Color placeholder = Color(0xFF9E9E9E);

  // ===== Text =====
  static const Color lightTextPrimary = Color(0xFF1D1D1D);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  // ===== Status =====
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ===== Dark Mode (placeholder) =====
  static const Color darkBackground = Color(0xFF1A1512);
  static const Color darkSurface = Color(0xFF2B2420);
  static const Color darkTextPrimary = Color(0xFFFFFAF3);
  static Color darkTextSecondary = darkTextPrimary.withValues(alpha: 0.6);

  // ===== Accent (splash gradient) =====
  static const Color cream = Color(0xFFFFFAF3);
  static const Color peach = Color(0xFFFFF2DB);
  static const Color sand = Color(0xFFFFE5BF);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, peach, sand, primary],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
}
