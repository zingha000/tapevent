import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FooterLogin extends StatelessWidget {
  final VoidCallback onPressed;

  const FooterLogin({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Sudah memiliki akun? ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: context.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onPressed,
          child: Text(
            'Masuk sekarang',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.linkBlue,
            ),
          ),
        ),
      ],
    );
  }
}
