import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../../widgets/register/header_section.dart';
import '../../widgets/register/role_selector.dart';
import '../../widgets/register/app_text_field.dart';
import '../../widgets/register/password_field.dart';
import '../../widgets/register/primary_button.dart';
import '../../widgets/register/footer_login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabase;

enum UserRole { mahasiswa, dosen }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.mahasiswa;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _nameFocus = FocusNode();
  final _idFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _idFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String get _idLabel => _role == UserRole.mahasiswa ? 'NIM' : 'NIDN / NIP';

  String get _idHint =>
      _role == UserRole.mahasiswa ? 'Masukkan NIM' : 'Masukkan NIDN atau NIP';

  void _onRoleChanged(UserRole role) {
    if (_role == role) return;
    setState(() {
      _role = role;
      _idController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'role': _role == UserRole.mahasiswa ? 'mahasiswa' : 'dosen',
          'identity_number': _idController.text.trim(), // NIM / NIDN-NIP
          'phone': _phoneController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.user != null) {
        if (!mounted) return;
        final lottieController = AnimationController(vsync: this);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/register.json',
                    controller: lottieController,
                    onLoaded: (composition) {
                      lottieController
                        ..duration = composition.duration
                        ..forward().then((_) {
                          if (mounted) Navigator.of(ctx).pop();
                        });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pendaftaran Berhasil!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Silakan login dengan akun kamu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
        lottieController.dispose();
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          // ===== Background register =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_register.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    onChanged: () => setState(() {}),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HeaderSection(),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: _nameController,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          focusNode: _nameFocus,
                          nextFocusNode: _idFocus,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nama wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        RoleSelector(
                          selectedRole: _role,
                          onRoleChanged: _onRoleChanged,
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child: AppTextField(
                            key: ValueKey(_role),
                            controller: _idController,
                            label: _idLabel,
                            hint: _idHint,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            focusNode: _idFocus,
                            nextFocusNode: _emailFocus,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return '$_idLabel wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'nama@email.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocus,
                          nextFocusNode: _phoneFocus,
                          showSuccess:
                              _emailController.text.contains('@') &&
                              _emailController.text.trim().isNotEmpty,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!v.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phoneController,
                          label: 'Nomor Telepon',
                          hint: '08xxxxxxxxxx',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          focusNode: _phoneFocus,
                          nextFocusNode: _passwordFocus,
                          showSuccess:
                              _phoneController.text.trim().length >= 10 &&
                              _phoneController.text.trim().isNotEmpty,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nomor telepon wajib diisi';
                            }
                            if (v.trim().length < 10) {
                              return 'Nomor telepon minimal 10 digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Masukkan password',
                          obscureText: _obscurePassword,
                          onToggleVisibility: () =>
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                          focusNode: _passwordFocus,
                          nextFocusNode: _confirmPasswordFocus,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (v.length < 8) {
                              return 'Password minimal 8 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _confirmPasswordController,
                          label: 'Konfirmasi Password',
                          hint: 'Ulangi password',
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                          focusNode: _confirmPasswordFocus,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Konfirmasi password wajib diisi';
                            }
                            if (v != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Daftar',
                          isLoading: _isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 20),
                        FooterLogin(onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ---- Tombol back ke halaman sebelumnya ----
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: context.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
