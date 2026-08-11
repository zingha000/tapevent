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
  static const Color darkBackground = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSecondaryBackground = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkPlaceholder = Color(0xFF757575);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static Color darkTextSecondary = darkTextPrimary.withValues(alpha: 0.6);

  // ===== Status =====
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ===== Accent (splash gradient) =====
  static const Color cream = Color(0xFFFFFAF3);
  static const Color peach = Color(0xFFFFF2DB);
  static const Color sand = Color(0xFFFFE5BF);

  // ===== Event Manage UI =====
  static const Color accentPink = Color(0xFFE94057);
  static const Color accentBlue = Color(0xFF2848D6);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color pageBackground = Color(0xFFF5F5F7);

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

  Color get linkBlue => isDark ? const Color(0xFF93A8E8) : const Color(0xFF1E3A8A);

  Color shadowColor([double opacity = 0.06]) =>
      isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: opacity);

  Color get pageScaffoldColor => isDark ? AppColors.darkBackground : AppColors.pageBackground;

  BoxDecoration get cardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      );
}
