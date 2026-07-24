import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;
  final bool showSuccess;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String? Function(String?)? validator;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    this.showSuccess = false,
    this.focusNode,
    this.nextFocusNode,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          onFieldSubmitted: nextFocusNode != null
              ? (_) => nextFocusNode!.requestFocus()
              : null,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              color: AppColors.placeholder,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: AppColors.placeholder,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.secondaryBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
