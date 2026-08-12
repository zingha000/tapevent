import 'package:flutter/material.dart';
import '../widgets/register/primary_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'about_screen.dart';

/// Halaman pembuka (onboarding): background gambar event + gradasi gelap,
/// konten di bagian bawah dengan dua tombol (Daftar & Masuk) serta
/// satu link kecil "Tentang TapEvent".
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== 1. BACKGROUND GAMBAR (asset yang sudah ada) =====
          Image.asset(
            'assets/images/tapevent_background.png',
            fit: BoxFit.cover,
          ),

          // ===== 2. GRADASI GELAP DI ATAS GAMBAR (bukan putih polos) =====
          // Agar teks di atasnya tetap terbaca.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000), // transparan di atas
                  Color(0x99000000), // semakin gelap di tengah
                  Color(0xF2000000), // hampir hitam di bawah
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ===== 3. KONTEN DI BAGIAN BAWAH =====
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Tagline (kata besar) ----
                    const Text(
                      'Kelola event kampus jadi mudah',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ---- Lorem ipsum (kata lebih kecil) ----
                    const Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Sed do eiusmod tempor incididunt ut labore et dolore magna '
                      'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
                      'ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ---- Tombol Daftar ----
                    PrimaryButton(
                      label: 'Daftar Sekarang',
                      onPressed: () => _openRegister(context),
                    ),
                    const SizedBox(height: 12),

                    // ---- Tombol Masuk ----
                    _SecondaryButton(
                      label: 'Masuk',
                      onPressed: () => _openLogin(context),
                    ),
                    const SizedBox(height: 24),

                    // ---- Link kecil "Tentang TapEvent" ----
                    Center(
                      child: GestureDetector(
                        onTap: () => _openAbout(context),
                        child: Text(
                          'Tentang TapEvent',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol sekunder bergaya button (bukan link) untuk aksi "Masuk".
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _SecondaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB80028),
          ),
        ),
      ),
    );
  }
}
