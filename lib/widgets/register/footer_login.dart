import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FooterLogin extends StatelessWidget {
  final VoidCallback onPressed;

  const FooterLogin({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sudah memiliki akun?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onPressed,
          child: const Text(
            'Masuk sekarang',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
