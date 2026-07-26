import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum PasswordStrength { none, weak, medium, strong }

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? errorText;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscureText,
    required this.onToggleVisibility,
    this.errorText,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.showStrengthIndicator = true,
  });

  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 8) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final strength = calculateStrength(controller.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              textInputAction: textInputAction,
              validator: validator,
              onFieldSubmitted: nextFocusNode != null
                  ? (_) => nextFocusNode!.requestFocus()
                  : null,
              style: TextStyle(
                fontSize: 16,
                color: context.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: context.placeholderColor,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: context.placeholderColor,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: context.placeholderColor,
                  ),
                  onPressed: onToggleVisibility,
                ),
                filled: true,
                fillColor: context.secondaryBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.border),
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
            if (showStrengthIndicator && controller.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StrengthIndicator(strength: strength),
            ],
          ],
        );
      },
    );
  }
}

class _StrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const _StrengthIndicator({required this.strength});

  Color get _color {
    switch (strength) {
      case PasswordStrength.none:
        return AppColors.border;
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return const Color(0xFFF59E0B);
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Lemah';
      case PasswordStrength.medium:
        return 'Sedang';
      case PasswordStrength.strong:
        return 'Kuat';
    }
  }

  int get _filledSegments {
    switch (strength) {
      case PasswordStrength.none:
        return 0;
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.medium:
        return 2;
      case PasswordStrength.strong:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: index < _filledSegments
                        ? _color
                        : context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _color,
          ),
        ),
      ],
    );
  }
}
