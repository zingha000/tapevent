import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StaticInfoScreen extends StatelessWidget {
  final String title;
  final String content;
  const StaticInfoScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(content, style: TextStyle(fontSize: 14, height: 1.6, color: context.textSecondary)),
      ),
    );
  }
}