import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../main.dart' show supabase;
import 'event_edit_screen.dart';

class EventManageScreen extends StatefulWidget {
  final Event event;
  const EventManageScreen({super.key, required this.event});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen> {
  late final TextEditingController _docController;
  late final TextEditingController _certController;
  late Event _event;
  bool _savingDoc = false;
  bool _savingCert = false;
  bool _showAccessCode = false;

  @override
  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _docController = TextEditingController(
      text: widget.event.documentationUrl ?? '',
    );
    _certController = TextEditingController(
      text: widget.event.certificateUrl ?? '',
    );
  }

  @override
  void dispose() {
    _docController.dispose();
    _certController.dispose();
    super.dispose();
  }

  Future<void> _saveField(
    String column,
    String value,
    void Function(bool) setLoading,
  ) async {
    setLoading(true);
    try {
      await supabase
          .from('events')
          .update({column: value.trim().isEmpty ? null : value.trim()})
          .eq('id', widget.event.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tautan berhasil disimpan')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan, coba lagi')),
      );
    } finally {
      if (mounted) setLoading(false);
    }
  }

  void _showQrDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QR Absensi',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 14 * anim.value,
            sigmaY: 14 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'QR Absensi Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        QrImageView(
                          data: widget.event.id,
                          size: 270,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Tunjukkan QR ini ke peserta untuk absen',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tutup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_event);
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: Text(_event.title, overflow: TextOverflow.ellipsis),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Banner + deskripsi event
            Container(
              width: double.infinity,
              height: 160,
              color: AppColors.sand,
              child: _event.bannerUrl != null
                  ? Image.network(_event.bannerUrl!, fit: BoxFit.cover)
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: Colors.white70,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventEditScreen(event: _event),
                            ),
                          );
                          if (result != null && result is Event) {
                            setState(() => _event = result);
                          }
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _event.description ?? 'Belum ada deskripsi.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),

                const SizedBox(height: 24),

                // Tombol Tampilkan QR — full width
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _showQrDialog,
                    icon: const Icon(
                      Icons.qr_code_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Tampilkan QR Absensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Link dokumentasi — submit terpisah
                _LinkSection(
                  label: 'Link Dokumentasi (Drive)',
                  controller: _docController,
                  isLoading: _savingDoc,
                  onSubmit: () => _saveField(
                    'documentation_url',
                    _docController.text,
                    (v) => setState(() => _savingDoc = v),
                  ),
                ),

                const SizedBox(height: 20),

                // Link sertifikat — submit terpisah (biasanya diisi belakangan)
                _LinkSection(
                  label: 'Link Sertifikat (Drive)',
                  controller: _certController,
                  isLoading: _savingCert,
                  onSubmit: () => _saveField(
                    'certificate_url',
                    _certController.text,
                    (v) => setState(() => _savingCert = v),
                  ),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 12),

                // Menu Ganti Kode Akses — tersembunyi sampai diklik
                InkWell(
                  onTap: () =>
                      setState(() => _showAccessCode = !_showAccessCode),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.vpn_key_outlined,
                          size: 18,
                          color: AppColors.lightTextPrimary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Ganti Kode Akses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          _showAccessCode
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: AppColors.lightTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _showAccessCode
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode Akses Saat Ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _event.accessCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: generate kode akses baru, update ke Supabase
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Buat Kode Baru',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _LinkSection({
    required this.label,
    required this.controller,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'https://drive.google.com/...',
            filled: true,
            fillColor: AppColors.lightSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
