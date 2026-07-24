import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Buat Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
            letterSpacing: -0.32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daftar untuk mulai menggunakan TapEvent',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
