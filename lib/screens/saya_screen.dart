import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../main.dart' show supabase;
import 'login_screen.dart';

class SayaScreen extends StatelessWidget {
  const SayaScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Halaman Saya'),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _logout(context),
                icon: Icon(AppIcons.logout, color: AppColors.primary),
                label: Text(
                  'Logout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}