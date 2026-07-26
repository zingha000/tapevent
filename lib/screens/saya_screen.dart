import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../services/profile_service.dart';
import '../main.dart' show supabase, toggleDarkMode;
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'static_info_screen.dart';
import 'admin_approval_screen.dart';

class SayaScreen extends StatefulWidget {
  const SayaScreen({super.key});

  @override
  State<SayaScreen> createState() => _SayaScreenState();
}

class _SayaScreenState extends State<SayaScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = supabase.auth.currentUser?.id;
    _profileFuture = userId != null ? ProfileService.fetchMyProfile(userId) : Future.value(null);
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final isAdmin = profile?['is_admin'] == true;
                final fullName = profile?['full_name'] as String? ?? '-';
                final role = profile?['role'] == 'dosen' ? 'Dosen' : 'Mahasiswa';

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF62440), Color(0xFFD81336), Color(0xFFB80E2C)],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 55,
                                left: MediaQuery.of(context).size.width / 2 - 70,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFFAF3).withOpacity(0.10),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 65,
                                left: MediaQuery.of(context).size.width / 2 - 55,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFE5BF).withOpacity(0.12),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 85,
                                left: MediaQuery.of(context).size.width / 2 + 30,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFF2DB).withOpacity(0.18),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profil Saya',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 38,
                                        backgroundColor: AppColors.primary.withOpacity(0.15),
                                        child: Text(
                                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalScreen()));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Persetujuan Event',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Setujui atau tolak event baru',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: context.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            _SectionLabel('Akun'),
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: 'Data Pribadi',
              onTap: () async {
                final profile = await _profileFuture;
                if (profile == null || !mounted) return;
                await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)));
                setState(_load);
              },
            ),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              label: 'Keamanan',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              },
            ),

            const SizedBox(height: 8),
            _SectionLabel('Preferensi'),
            _DarkModeTile(isDark: isDark),

            const SizedBox(height: 8),
            _SectionLabel('Lainnya'),
            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Kebijakan & Privasi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticInfoScreen(
                    title: 'Kebijakan & Privasi',
                    content: 'Konten kebijakan privasi TapEvent akan ditambahkan di sini.',
                  ),
                ),
              ),
            ),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              label: 'Bantuan',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticInfoScreen(
                    title: 'Bantuan',
                    content: 'Halaman bantuan/FAQ TapEvent akan ditambahkan di sini.',
                  ),
                ),
              ),
            ),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'Tentang Aplikasi',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaticInfoScreen(
                    title: 'Tentang Aplikasi',
                    content: 'TapEvent — Digital Campus Event Management Platform.',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(AppIcons.logout, color: AppColors.primary, size: 18),
                  label: Text('Logout', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DarkModeTile extends StatelessWidget {
  final bool isDark;
  const _DarkModeTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: context.textPrimary,
        size: 22,
      ),
      title: Text('Mode Gelap', style: TextStyle(fontSize: 14, color: context.textPrimary)),
      trailing: Switch(
        value: isDark,
        onChanged: (v) => toggleDarkMode(v),
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: context.textPrimary, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: context.textPrimary)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
    );
  }
}
