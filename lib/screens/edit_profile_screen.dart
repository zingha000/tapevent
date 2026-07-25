import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';
import '../main.dart' show supabase;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['full_name'] ?? '');
    _idController = TextEditingController(text: widget.profile['identity_number'] ?? '');
    _phoneController = TextEditingController(text: widget.profile['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await ProfileService.updateProfile(userId, {
        'full_name': _nameController.text.trim(),
        'identity_number': _idController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan, coba lagi')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Data Pribadi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Label('Nama Lengkap'),
          TextField(controller: _nameController, decoration: _decoration()),
          const SizedBox(height: 16),

          _Label(widget.profile['role'] == 'dosen' ? 'NIDN/NIP' : 'NIM'),
          TextField(controller: _idController, decoration: _decoration()),
          const SizedBox(height: 16),

          _Label('Nomor Telepon'),
          TextField(controller: _phoneController, decoration: _decoration()),
          const SizedBox(height: 16),

          _Label('Email'),
          TextField(
            enabled: false,
            controller: TextEditingController(text: widget.profile['email'] ?? ''),
            decoration: _decoration().copyWith(fillColor: Colors.black.withOpacity(0.03)),
          ),
          const SizedBox(height: 4),
          Text('Email tidak dapat diubah', style: TextStyle(fontSize: 11, color: context.textSecondary)),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: context.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
    );
  }
}