import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  Uint8List? _avatarBytes;

  String? get _currentAvatarUrl => widget.profile['avatar_url'] as String?;

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

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _avatarBytes = bytes);
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_avatarBytes == null) return null;
    final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('event-banners').uploadBinary(fileName, _avatarBytes!);
    return supabase.storage.from('event-banners').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final fields = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'identity_number': _idController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_avatarBytes != null) {
        final avatarUrl = await _uploadAvatar(userId);
        if (avatarUrl != null) fields['avatar_url'] = avatarUrl;
      }

      await ProfileService.updateProfile(userId, fields);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('EditProfile error: $e');
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
    final fullName = widget.profile['full_name'] as String? ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

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
          // ─── Avatar ───
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _avatarBytes != null
                        ? MemoryImage(_avatarBytes!)
                        : (_currentAvatarUrl != null
                            ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                            : null),
                    child: _avatarBytes == null && _currentAvatarUrl == null
                        ? Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.bg, width: 2.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
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
