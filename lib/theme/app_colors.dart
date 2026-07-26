import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== Primary =====
  static const Color primary = Color(0xFFFF2D4D);
  static const Color primaryHover = Color(0xFFE62342);

  // ===== Light Mode =====
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF8F8F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5E5);
  static const Color placeholder = Color(0xFF9E9E9E);
  static const Color lightTextPrimary = Color(0xFF1D1D1D);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  // ===== Dark Mode =====
  static const Color darkBackground = Color(0xFF1A1512);
  static const Color darkSurface = Color(0xFF2B2420);
  static const Color darkSecondaryBackground = Color(0xFF352E28);
  static const Color darkBorder = Color(0xFF3D3530);
  static const Color darkPlaceholder = Color(0xFF8A7E76);
  static const Color darkTextPrimary = Color(0xFFFFFAF3);
  static Color darkTextSecondary = darkTextPrimary.withOpacity(0.6);

  // ===== Status =====
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

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

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get secondaryBg => isDark ? AppColors.darkSecondaryBackground : AppColors.secondaryBackground;
  Color get border => isDark ? AppColors.darkBorder : AppColors.border;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get placeholderColor => isDark ? AppColors.darkPlaceholder : AppColors.placeholder;

  Color shadowColor([double opacity = 0.06]) =>
      isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(opacity);
}
