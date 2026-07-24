import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: const SafeArea(
        child: Center(child: Text('Halaman Riwayat')),
      ),
    );
  }
}