import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Controller untuk animasi masuk logo & teks.
  late final AnimationController _controller;

  /// Animasi fade-in (opacity 0 -> 1).
  late final Animation<double> _fade;

  /// Animasi scale (0.8 -> 1.0 dengan kurva halus easeOutCubic).
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi controller animasi (durasi 1400ms agar lebih smooth).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Kurva fade memakai easeInOut agar logo muncul perlahan & halus.
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 3. Kurva scale memakai easeOutCubic untuk efek halus tanpa overshoot.
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 4. Jalankan animasi & mulai hitung mundur navigasi.
    _controller.forward();
    _goToOnboarding();
  }

  /// Navigasi otomatis ke [OnboardingScreen] setelah 3 detik.
  Future<void> _goToOnboarding() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return; // Cegah error jika widget sudah di-unmount.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Selalu dispose controller.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang putih polos.
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ===== 1. ORNAMEN SPLASHSCREEN (Asset di Bagian Bawah) =====
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/ornamen_splashscreen.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // ===== 2. KONTEN TENGAH (Logo + Judul + Tagline) =====
          Center(
            // Gabungan animasi fade + scale untuk seluruh grup logo & teks.
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  // Diangkat sedikit agar seimbang dengan wave di bawah.
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---- Logo full (logo.png) ----
                      Container(
                        width: 240,
                        height: 160,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- Tagline ----
                      const Text(
                        'Kelola event kampus jadi mudah',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
