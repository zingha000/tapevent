import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../widgets/screen_header.dart';
import '../services/profile_service.dart';
import '../main.dart' show supabase, themeNotifier, toggleDarkMode;
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'static_info_screen.dart';

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
            const ScreenHeader(title: 'Saya', subtitle: 'Kelola akun dan preferensi'),

            FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          (profile?['full_name'] as String?)?.isNotEmpty == true
                              ? profile!['full_name'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?['full_name'] ?? '-',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?['role'] == 'dosen' ? 'Dosen' : 'Mahasiswa',
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
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
