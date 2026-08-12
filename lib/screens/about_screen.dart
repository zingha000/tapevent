import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Halaman informasi aplikasi TapEvent.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tentang TapEvent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Logo (logo.png) ----
            Center(
              child: Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/images/logo_horizontal.png',
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Versi 1.0.0',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ),
            const SizedBox(height: 32),

            // ---- Deskripsi ----
            Text(
              'TapEvent adalah platform untuk mengelola event kampus jadi '
              'mudah: membuat event, mengelola pendaftaran, presensi via QR '
              'code, dan melihat riwayat kehadiran dalam satu aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // ---- Poin fitur ----
            _FeatureRow(icon: Icons.event_rounded, label: 'Buat & kelola event'),
            _FeatureRow(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Presensi via QR code',
            ),
            _FeatureRow(
              icon: Icons.history_rounded,
              label: 'Riwayat kehadiran',
            ),
            _FeatureRow(
              icon: Icons.groups_rounded,
              label: 'Kolaborasi panitia',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
