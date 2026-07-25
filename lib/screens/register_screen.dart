import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
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
    _animController.dispose();
    super.dispose();
  }

  String get _idLabel => _role == UserRole.mahasiswa ? 'NIM' : 'NIDN / NIP';

  String get _idHint =>
      _role == UserRole.mahasiswa ? 'Masukkan NIM' : 'Masukkan NIDN atau NIP';

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _idController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _passwordController.text.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(_passwordController.text) &&
        RegExp(r'[0-9]').hasMatch(_passwordController.text) &&
        _emailController.text.contains('@');
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil, silakan login')),
        );
        Navigator.of(context).pop(); // kembali ke halaman Login
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
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
                        RoleSelector(
                          selectedRole: _role,
                          onRoleChanged: _onRoleChanged,
                        ),
                        const SizedBox(height: 24),
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
                          label: 'Email Kampus',
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
                          onToggleVisibility: () => setState(
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
                            if (!RegExp(r'[A-Z]').hasMatch(v)) {
                              return 'Harus mengandung huruf besar';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(v)) {
                              return 'Harus mengandung angka';
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
                            () => _obscureConfirmPassword =
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
                          isEnabled: _isFormValid,
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
        ),
      ),
    );
  }
}
