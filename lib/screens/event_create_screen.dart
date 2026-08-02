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
  final _locationController = TextEditingController();
  final _organizerController = TextEditingController();
  final _contactController = TextEditingController();
  final _formUrlController = TextEditingController();

  String? _category;
  DateTime? _startDate;
  DateTime? _endDate;
  final _maxParticipantsController = TextEditingController();
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
    _locationController.dispose();
    _organizerController.dispose();
    _contactController.dispose();
    _formUrlController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            todayForegroundColor: WidgetStatePropertyAll(AppColors.primary),
            todayBackgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.1)),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.primary;
              return null;
            }),
            rangeSelectionBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: Colors.white,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return null;
            }),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai harus dipilih terlebih dahulu')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            todayForegroundColor: WidgetStatePropertyAll(AppColors.primary),
            todayBackgroundColor: WidgetStatePropertyAll(AppColors.primary.withValues(alpha: 0.1)),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.primary;
              return null;
            }),
            rangeSelectionBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: Colors.white,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return null;
            }),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
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
        const SnackBar(content: Text('Tanggal mulai event wajib dipilih')),
      );
      return;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal berakhir event wajib dipilih')),
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
        endDate: _endDate,
        maxParticipants: _maxParticipantsController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text.trim()),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
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
        SnackBar(content: Text('Gagal: $e')),
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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Buat Event',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.bg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
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
                  color: context.secondaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _bannerBytes != null ? AppColors.primary : AppColors.border,
                    width: _bannerBytes != null ? 2 : 1,
                  ),
                ),
                child: _bannerBytes != null
                    ? Image.memory(_bannerBytes!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 24,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ketuk untuk unggah banner',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Format JPG/PNG, maks 2MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ukuran ideal: 1200 x 630 px (rasio ~1.9:1)',
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
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration('Pilih kategori'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Tanggal Mulai'),
            InkWell(
              onTap: _pickStartDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Pilih tanggal mulai'),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: _startDate == null ? context.textSecondary : AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _startDate == null
                            ? 'Belum dipilih'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _startDate == null
                              ? context.textSecondary
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Tanggal Berakhir'),
            InkWell(
              onTap: _pickEndDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _decoration('Pilih tanggal berakhir'),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: _endDate == null ? context.textSecondary : AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _endDate == null
                            ? 'Belum dipilih'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _endDate == null
                              ? context.textSecondary
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Label('Maksimal Jumlah Peserta'),
            TextFormField(
              controller: _maxParticipantsController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Kosongkan jika tidak terbatas'),
            ),
            const SizedBox(height: 16),

            _Label('Lokasi'),
            TextFormField(
              controller: _locationController,
              decoration: _decoration('Contoh: Auditorium, Lab Komputer, dll'),
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
                  backgroundColor: AppColors.accentBlue,
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
      hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
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
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
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
