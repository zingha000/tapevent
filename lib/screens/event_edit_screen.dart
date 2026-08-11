import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;

class EventEditScreen extends StatefulWidget {
  final Event event;
  const EventEditScreen({super.key, required this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _organizerController;
  late final TextEditingController _contactController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _formUrlController;

  Uint8List? _newBannerBytes;
  bool _isSaving = false;

  String? _category;
  DateTime? _startDate;
  DateTime? _endDate;

  final _categories = [
    'Workshop',
    'Seminar',
    'Lomba',
    'Olahraga',
    'Sosial',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _taglineController = TextEditingController(
      text: widget.event.tagline ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.event.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.event.location ?? '',
    );
    _organizerController = TextEditingController(
      text: widget.event.organizerName,
    );
    _contactController = TextEditingController(
      text: widget.event.contactPerson ?? '',
    );
    _maxParticipantsController = TextEditingController(
      text: widget.event.maxParticipants?.toString() ?? '',
    );
    _formUrlController = TextEditingController(
      text: widget.event.registrationFormUrl ?? '',
    );
    _category = widget.event.category;
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _contactController.dispose();
    _maxParticipantsController.dispose();
    _formUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
      setState(() => _newBannerBytes = bytes);
    }
  }

  Future<String?> _uploadBanner() async {
    if (_newBannerBytes == null) return widget.event.bannerUrl;
    final fileName =
        '${widget.event.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage
        .from('event-banners')
        .uploadBinary(fileName, _newBannerBytes!);
    return supabase.storage.from('event-banners').getPublicUrl(fileName);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai event wajib diisi')),
      );
      return;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal berakhir event wajib diisi')),
      );
      return;
    }
    final formUrl = _formUrlController.text.trim();
    if (formUrl.isNotEmpty && !EventService.isGoogleFormUrl(formUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Link harus berupa Google Form (forms.gle / docs.google.com/forms)',
          ),
        ),
      );
      return;
    }
    final maxParticipantsRaw = _maxParticipantsController.text.trim();
    final maxParticipants = maxParticipantsRaw.isEmpty
        ? null
        : int.tryParse(maxParticipantsRaw);
    if (maxParticipantsRaw.isNotEmpty && maxParticipants == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal peserta harus berupa angka')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bannerUrl = await _uploadBanner();

      await EventService.updateEvent(widget.event.id, {
        'title': _titleController.text.trim(),
        'tagline': _taglineController.text.trim().isEmpty
            ? null
            : _taglineController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'category': _category,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'max_participants': maxParticipants,
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'organizer_name': _organizerController.text.trim(),
        'contact_person': _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        'registration_form_url': formUrl.isEmpty ? null : formUrl,
        'banner_url': bannerUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event berhasil diperbarui')),
      );
      final updatedEvent = Event(
        id: widget.event.id,
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
        maxParticipants: maxParticipants,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        organizerName: _organizerController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        registrationFormUrl: formUrl.isEmpty ? null : formUrl,
        accessCode: widget.event.accessCode,
        status: widget.event.status,
        documentationUrl: widget.event.documentationUrl,
        certificateUrl: widget.event.certificateUrl,
        createdBy: widget.event.createdBy,
        rejectionReason: widget.event.rejectionReason,
        qrSecret: widget.event.qrSecret,
        proofDocumentUrl: widget.event.proofDocumentUrl,
        participantCount: widget.event.participantCount,
      );
      Navigator.of(context).pop(updatedEvent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageScaffoldColor,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentPink, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.paddingOf(context).top + 8,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Edit Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perbarui Detail Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickBanner,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: _newBannerBytes != null
                        ? Image.memory(_newBannerBytes!, fit: BoxFit.cover)
                        : (widget.event.bannerUrl != null
                              ? Image.network(
                                  widget.event.bannerUrl!,
                                  fit: BoxFit.cover,
                                )
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
                                )),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ketuk gambar di atas untuk mengganti banner',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: context.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Judul Event'),
                      TextField(
                        controller: _titleController,
                        decoration: _decoration('Judul event'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Tagline'),
                      TextField(
                        controller: _taglineController,
                        decoration: _decoration('Opsional'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Deskripsi'),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _decoration('Deskripsi event'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Kategori'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: _decoration('Pilih kategori'),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v),
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
                      TextField(
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Kosongkan jika tidak terbatas'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Lokasi'),
                      TextField(
                        controller: _locationController,
                        decoration: _decoration('Lokasi event'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Nama Organisasi/Ormawa'),
                      TextField(
                        controller: _organizerController,
                        decoration: _decoration('Nama organisasi'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Contact Person'),
                      TextField(
                        controller: _contactController,
                        decoration: _decoration('Nomor kontak'),
                      ),
                      const SizedBox(height: 16),

                      _Label('Link Formulir Pendaftaran (Google Form)'),
                      TextField(
                        controller: _formUrlController,
                        keyboardType: TextInputType.url,
                        decoration: _decoration('https://forms.gle/...'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hanya link Google Form yang diizinkan (contoh: https://forms.gle/... atau https://docs.google.com/forms/...)',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
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
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
      filled: true,
      fillColor: context.bg,
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
