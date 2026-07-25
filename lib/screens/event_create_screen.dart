import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerController = TextEditingController();
  final _contactController = TextEditingController();
  final _formUrlController = TextEditingController();

  String? _category;
  DateTime? _startDate;
  bool _isSaving = false;

  Uint8List? _bannerBytes;
  Uint8List? _proofBytes;
  bool _uploadingProof = false;


  final _categories = [
    'Workshop',
    'Seminar',
    'Lomba',
    'Olahraga',
    'Sosial',
    'Lainnya',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _contactController.dispose();
    _formUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickBanner() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _bannerBytes = bytes);
    }
  }

  Future<String?> _uploadBanner(String userId) async {
    if (_bannerBytes == null) return null;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('event-banners').uploadBinary(fileName, _bannerBytes!);
    return supabase.storage.from('event-banners').getPublicUrl(fileName);
  }

  Future<void> _pickProofFile() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _proofBytes = bytes);
    }
  }

  Future<String?> _uploadProofFile(String userId) async {
    if (_proofBytes == null) return null;
    setState(() => _uploadingProof = true);
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('event-proofs')
          .uploadBinary(fileName, _proofBytes!);
      return supabase.storage.from('event-proofs').getPublicUrl(fileName);
    } finally {
      if (mounted) setState(() => _uploadingProof = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal event wajib dipilih')),
      );
      return;
    }
    if (_proofBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti lembar pengesahan wajib diunggah')),
      );
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final bannerUrl = await _uploadBanner(userId);
      final proofUrl = await _uploadProofFile(userId);

      await EventService.createEvent(
        title: _titleController.text.trim(),
        tagline: _taglineController.text.trim().isEmpty
            ? null
            : _taglineController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        bannerUrl: bannerUrl,
        category: _category,
        startDate: _startDate!,
        organizerName: _organizerController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        registrationFormUrl: _formUrlController.text.trim().isEmpty
            ? null
            : _formUrlController.text.trim(),
        proofDocumentUrl: proofUrl,
        createdBy: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event berhasil dibuat, menunggu persetujuan admin'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat event, coba lagi')),
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
        title: const Text('Buat Event Anda'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner upload
            InkWell(
              onTap: _pickBanner,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _bannerBytes != null
                    ? Image.memory(_bannerBytes!, fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ketuk untuk unggah banner',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk gambar di atas untuk memilih banner event',
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            _Label('Judul Event'),
            TextFormField(
              controller: _titleController,
              decoration: _decoration('Masukkan judul event'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            _Label('Tagline'),
            TextFormField(
              controller: _taglineController,
              decoration: _decoration('Opsional'),
            ),
            const SizedBox(height: 16),

            _Label('Deskripsi'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _decoration('Ceritakan tentang event ini'),
            ),
            const SizedBox(height: 16),

            _Label('Kategori'),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _decoration('Pilih kategori'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),

            _Label('Tanggal Pelaksanaan'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Pilih tanggal'),
                child: Text(
                  _startDate == null
                      ? 'Belum dipilih'
                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                  style: TextStyle(
                    color: _startDate == null
                        ? context.textSecondary
                        : context.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Nama Organisasi/Ormawa'),
            TextFormField(
              controller: _organizerController,
              decoration: _decoration('Contoh: HIMA Sistem Informasi'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama organisasi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),

            _Label('Contact Person'),
            TextFormField(
              controller: _contactController,
              decoration: _decoration('Nomor yang bisa dihubungi peserta'),
            ),
            const SizedBox(height: 16),

            _Label('Link Formulir Pendaftaran (Google Form)'),
            TextFormField(
              controller: _formUrlController,
              decoration: _decoration('https://forms.gle/...'),
            ),
            const SizedBox(height: 16),

            _Label('Bukti Lembar Pengesahan (TTD Dosen)'),
            InkWell(
              onTap: _uploadingProof ? null : _pickProofFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofBytes != null
                        ? AppColors.primary
                        : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _proofBytes != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_outlined,
                      color: _proofBytes != null
                          ? AppColors.primary
                          : context.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _proofBytes != null
                            ? 'File terpilih, siap diunggah'
                            : 'Ketuk untuk pilih file',
                        style: TextStyle(
                          fontSize: 13,
                          color: _proofBytes != null
                              ? context.textPrimary
                              : context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Wajib diisi, digunakan admin untuk meninjau pengajuan event',
              style: TextStyle(
                fontSize: 11,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ajukan Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Event akan tayang setelah disetujui admin',
                style: TextStyle(
                  fontSize: 12,
                color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
    );
  }
}
