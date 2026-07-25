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
  late final TextEditingController _organizerController;
  late final TextEditingController _contactController;

  Uint8List? _newBannerBytes;
  bool _isSaving = false;

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
    _organizerController = TextEditingController(
      text: widget.event.organizerName,
    );
    _contactController = TextEditingController(
      text: widget.event.contactPerson ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _contactController.dispose();
    super.dispose();
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
        'organizer_name': _organizerController.text.trim(),
        'contact_person': _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        'banner_url': bannerUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event berhasil diperbarui')),
      );
      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        tagline: _taglineController.text.trim().isEmpty
            ? null
            : _taglineController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        organizerName: _organizerController.text.trim(),
        contactPerson: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        bannerUrl: bannerUrl,
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
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Edit Event'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
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
