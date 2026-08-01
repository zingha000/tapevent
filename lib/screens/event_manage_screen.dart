import 'dart:async';
import 'dart:io';
import 'dart:js_interop';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../main.dart' show supabase;
import 'event_edit_screen.dart';
import '../services/event_service.dart';
import '../widgets/lottie_loading.dart';

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
  late Future<List<Map<String, dynamic>>> _organizersFuture;
  bool _savingDoc = false;
  bool _savingCert = false;
  bool _uploadingCsv = false;
  bool _downloadingPdf = false;
  late Future<List<Map<String, dynamic>>> _participantsFuture;

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
    _participantsFuture = EventService.fetchParticipants(_event.id);
    _organizersFuture = EventService.fetchOrganizers(_event.id);
    _autoCompleteIfExpired();
  }

  Future<void> _autoCompleteIfExpired() async {
    if (_event.status != 'active' || _event.endDate == null) return;
    if (_event.endDate!.isAfter(DateTime.now())) return;
    try {
      await EventService.completeEvent(_event.id);
      if (!mounted) return;
      final completed = _event.copyWith(status: 'completed');
      setState(() => _event = completed);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event otomatis ditandai selesai karena sudah lewat tanggal')),
      );
    } catch (e) {
      debugPrint('Auto-complete failed: $e');
    }
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

  Future<void> _openEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventEditScreen(event: _event)),
    );
    if (result != null && result is Event) {
      setState(() => _event = result);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _confirmComplete() async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Akhiri Event',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim.value,
            sigmaY: 12 * anim.value,
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akhiri Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Event akan ditandai sebagai selesai. Peserta tidak akan lagi melihat event ini di beranda.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.black12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Akhiri',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

    if (confirmed == true && mounted) {
      try {
        await EventService.completeEvent(_event.id);
        if (!mounted) return;
        final completed = _event.copyWith(status: 'completed');
        setState(() => _event = completed);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event berhasil diselesaikan')));
        Navigator.of(context).pop(completed);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyelesaikan event, coba lagi')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final reasonController = TextEditingController();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hapus Event',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim.value,
            sigmaY: 12 * anim.value,
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hapus Event',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tindakan ini tidak bisa dibatalkan. Jelaskan alasan penghapusan:',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Event dibatalkan karena...',
                            filled: true,
                            fillColor: context.bg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.black12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (reasonController.text.trim().isEmpty)
                                      return;
                                    Navigator.of(context).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

    if (confirmed == true && mounted) {
      try {
        await EventService.deleteEvent(_event.id, reasonController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event berhasil dihapus')));
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus event')));
      }
    }
  }

  void _showAccessCodePopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ganti Kode Akses',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12 * anim.value, sigmaY: 12 * anim.value),
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.vpn_key_rounded, color: AppColors.accentBlue, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Ganti Kode Akses',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kode akses hanya perlu diketahui oleh penyelenggara. Jika ada orang luar yang mengetahuinya, segera buat kode baru.',
                                  style: TextStyle(fontSize: 12, color: AppColors.accentBlue, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmRegenerateAccessCode();
                            },
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                            label: const Text('Buat Kode Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Tutup', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
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

  Future<void> _confirmRegenerateAccessCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buat Kode Akses Baru?'),
        content: const Text('Kode lama tidak akan berlaku lagi. Semua orang (termasuk kamu) perlu kode baru ini untuk masuk lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Buat Baru', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final newCode = await EventService.regenerateAccessCode(_event.id);
      if (mounted) {
        setState(() => _event = _event.copyWith(accessCode: newCode));
        _showNewCodePopup(newCode);
      }
    }
  }

  void _showNewCodePopup(String newCode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Kode Baru',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12 * anim.value, sigmaY: 12 * anim.value),
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Kode Akses Baru',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Kode ini hanya ditampilkan sekali. Salin sekarang, setelah ini tidak bisa dilihat lagi.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: context.bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            newCode.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.w800, color: AppColors.accentBlue),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: newCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kode akses disalin')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.accentBlue),
                            label: const Text('Salin Kode', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accentBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Tutup', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
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

  void _showAksiPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Aksi',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12 * anim.value, sigmaY: 12 * anim.value),
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.more_horiz_rounded, color: AppColors.accentBlue, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Aksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('Pilih tindakan untuk event ini',
                            style: TextStyle(fontSize: 13, color: context.textSecondary)),
                        const SizedBox(height: 20),
                        if (_event.status == 'active')
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _confirmComplete();
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                              label: const Text('Akhiri Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        if (_event.status == 'active') const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _confirmDelete();
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                            label: const Text('Hapus Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Tutup', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
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
                  child: _QrDialogWidget(event: _event),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() => _uploadingCsv = true);
    try {
      var content = String.fromCharCodes(result.files.single.bytes!);
      if (content.isNotEmpty && content.codeUnitAt(0) == 0xFEFF) {
        content = content.substring(1);
      }
      final codec = Csv(dynamicTyping: false, autoDetect: true);
      final rows = codec.decode(content);

      final nims = rows
          .skip(1)
          .map((row) => row[0].toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();

      if (nims.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada NIM ditemukan di CSV. Pastikan baris pertama header dan kolom pertama berisi NIM.',
            ),
          ),
        );
        return;
      }

      final res = await EventService.uploadParticipants(_event.id, nims);

      if (!mounted) return;
      setState(() {
        _participantsFuture = EventService.fetchParticipants(_event.id);
      });

      final matched = res['matched'] as int;
      final unmatched = res['unmatched'] as List;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(
            unmatched.isEmpty
                ? '$matched peserta berhasil ditambahkan'
                : '$matched ditambahkan, ${unmatched.length} NIM tidak ditemukan: ${unmatched.join(', ')}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses CSV: $e')));
    } finally {
      if (mounted) setState(() => _uploadingCsv = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final participants = await _participantsFuture;
      if (!mounted) return;
      if (participants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada peserta untuk diunduh')),
        );
        return;
      }

      String formatDate(DateTime? d) =>
          d == null ? '-' : '${d.day}/${d.month}/${d.year}';
      final rows = participants.map((p) {
        final profile = p['profiles'] as Map<String, dynamic>?;
        final attendanceList = p['attendances'] as List?;
        final hasAttended = attendanceList != null && attendanceList.isNotEmpty;
        final cancellationRequested = p['cancellation_requested'] == true;
        return [
          profile?['identity_number']?.toString() ?? '-',
          profile?['full_name']?.toString() ?? '-',
          hasAttended ? 'Hadir' : 'Belum hadir',
          cancellationRequested ? 'Diajukan' : '-',
        ];
      }).toList();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          ),
          build: (context) => [
            pw.Text(
              _event.title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Penyelenggara: ${_event.organizerName}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.Text(
              'Tanggal: ${formatDate(_event.startDate)}'
              '${_event.endDate != null ? ' - ${formatDate(_event.endDate)}' : ''}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 6),
            pw.Text(
              'Daftar Peserta (${participants.length} orang)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['No', 'NIM/NIP', 'Nama', 'Status Hadir', 'Pembatalan'],
              data: [
                for (var i = 0; i < participants.length; i++)
                  ['${i + 1}', ...rows[i]],
              ],
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(36),
                1: pw.FixedColumnWidth(88),
                2: pw.FlexColumnWidth(),
                3: pw.FixedColumnWidth(88),
                4: pw.FixedColumnWidth(72),
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.6,
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final safeTitle = _event.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final filename = 'daftar_peserta_$safeTitle.pdf';
      if (kIsWeb) {
        _downloadPdfOnWeb(bytes, filename);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Daftar Peserta - ${_event.title}',
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF download failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  void _downloadPdfOnWeb(Uint8List bytes, String filename) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename;
    web.window.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  Future<void> _dropParticipant(Map<String, dynamic> participant) async {
    final reasonController = TextEditingController();
    final profile = participant['profiles'] as Map<String, dynamic>?;

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hapus Peserta',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim.value,
            sigmaY: 12 * anim.value,
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
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hapus ${profile?['full_name'] ?? 'Peserta'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jelaskan alasan penghapusan peserta ini:',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Salah input NIM saat upload',
                            filled: true,
                            fillColor: context.bg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.black12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (reasonController.text.trim().isEmpty)
                                      return;
                                    Navigator.of(context).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

    if (confirmed == true) {
      await EventService.dropParticipant(
        participant['id'],
        reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(
        () => _participantsFuture = EventService.fetchParticipants(_event.id),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Peserta berhasil dihapus')));
    }
  }

  Future<void> _respondCancellation(Map<String, dynamic> participant) async {
    final profile = participant['profiles'] as Map<String, dynamic>?;
    final reason = participant['cancellation_reason'] ?? '-';

    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Pengajuan Batal — ${profile?['full_name'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alasan dari peserta:',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(reason, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('reject'),
            child: Text(
              'Tolak',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('approve'),
            child: const Text('Terima', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (response == 'approve') {
      await EventService.approveCancellation(
        participant['id'],
        'Disetujui panitia',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pembatalan disetujui')));
    } else if (response == 'reject') {
      await EventService.rejectCancellation(participant['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengajuan ditolak')));
    } else {
      return;
    }

    setState(
      () => _participantsFuture = EventService.fetchParticipants(_event.id),
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
        backgroundColor:
            context.isDark ? context.bg : AppColors.pageBackground,
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE94057), Color(0xFF2848D6)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.paddingOf(context).top + 18,
                        20,
                        36,
                      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Event Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kelola Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                    ),
                    ),
                    const SizedBox(height: 154),
                  ],
                ),
                Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: Container(
                height: 190,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border, width: 1),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_event.bannerUrl != null)
                      Image.network(_event.bannerUrl!, fit: BoxFit.cover)
                    else
                      Container(
                        color: AppColors.sand,
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: [0.55, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_event.status == 'active')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentPink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Live Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Text(
                            _event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDate(_event.startDate),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openEditScreen,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppColors.accentBlue,
                              ),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppColors.accentBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.accentBlue,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _event.description ?? 'Belum ada deskripsi.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _showQrDialog,
                      icon: const Icon(
                        Icons.qr_code_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Tampilkan QR Absensi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Event Assets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AssetCard(
                    icon: Icons.folder_shared_rounded,
                    iconBg: const Color(0xFFEDE7FF),
                    iconColor: const Color(0xFF7B5CFF),
                    title: 'Link Dokumentasi',
                    subtitle: 'Share photos and video links',
                    controller: _docController,
                    placeholder: 'https://drive.google.com/...',
                    buttonLabel: 'Update Documentation',
                    isLoading: _savingDoc,
                    onSubmit: () => _saveField(
                      'documentation_url',
                      _docController.text,
                      (v) => setState(() => _savingDoc = v),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _AssetCard(
                    icon: Icons.workspace_premium_rounded,
                    iconBg: const Color(0xFFFFEEDB),
                    iconColor: const Color(0xFFFF8A3D),
                    title: 'Link Sertifikat',
                    subtitle: 'Provide certificate distribution link',
                    controller: _certController,
                    placeholder: 'https://drive.google.com/...',
                    buttonLabel: 'Update Certificate Link',
                    isLoading: _savingCert,
                    onSubmit: () => _saveField(
                      'certificate_url',
                      _certController.text,
                      (v) => setState(() => _savingCert = v),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Peserta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _downloadingPdf ? null : _downloadPdf,
                            icon: _downloadingPdf
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 16,
                                    color: AppColors.softBlue,
                                  ),
                            label: Text(
                              _downloadingPdf
                                  ? 'Menyiapkan...'
                                  : 'Download PDF',
                              style: const TextStyle(
                                color: AppColors.softBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.softBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _uploadingCsv ? null : _uploadCsv,
                            icon: _uploadingCsv
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.upload_file_rounded,
                                    size: 16,
                                    color: AppColors.softBlue,
                                  ),
                            label: Text(
                              _uploadingCsv ? 'Memproses...' : 'Upload CSV',
                              style: const TextStyle(
                                color: AppColors.softBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.softBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'Format CSV: baris pertama header, kolom pertama = NIM/NIP',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _participantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(width: 80, height: 80, child: LottieLoading()),
                          ),
                        );
                      }
                      final participants = snapshot.data ?? [];
                      if (participants.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Belum ada peserta terdaftar',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 640),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                context.bg,
                              ),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              headingTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              dataTextStyle: TextStyle(
                                fontSize: 13,
                                color: context.textPrimary,
                              ),
                              columns: const [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('NIM')),
                                DataColumn(label: Text('Nama')),
                                DataColumn(label: Text('Status Hadir')),
                                DataColumn(label: Text('Pembatalan')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: List.generate(participants.length, (index) {
                                final p = participants[index];
                                final profile =
                                    p['profiles'] as Map<String, dynamic>?;
                                final attendanceList =
                                    p['attendances'] as List?;
                                final hasAttended =
                                    attendanceList != null &&
                                    attendanceList.isNotEmpty;
                                final cancellationRequested =
                                    p['cancellation_requested'] == true;

                                return DataRow(
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(
                                      Text(profile?['identity_number'] ?? '-'),
                                    ),
                                    DataCell(
                                      Text(profile?['full_name'] ?? '-'),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasAttended
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          hasAttended ? 'Hadir' : 'Belum hadir',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: hasAttended
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      cancellationRequested
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Diajukan',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              '-',
                                              style: TextStyle(
                                                color: context.textSecondary,
                                              ),
                                            ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 96,
                                        height: 34,
                                        child: cancellationRequested
                                            ? OutlinedButton(
                                                onPressed: () =>
                                                    _respondCancellation(p),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.orange,
                                                  ),
                                                  foregroundColor:
                                                      Colors.orange,
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Tanggapi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            : OutlinedButton(
                                                onPressed: () =>
                                                    _dropParticipant(p),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                  foregroundColor: Colors.red,
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Hapus',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daftar Akses Kelola Event',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Semua orang yang pernah masuk lewat kode akses',
                      style: TextStyle(fontSize: 11, color: context.textSecondary)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _organizersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(width: 80, height: 80, child: LottieLoading()),
                          ),
                        );
                      }
                      final organizers = snapshot.data ?? [];
                      if (organizers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('Belum ada yang masuk', style: TextStyle(color: context.textSecondary)),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 480),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(context.bg),
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 56,
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              headingTextStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                              dataTextStyle: TextStyle(
                                fontSize: 13,
                                color: context.textPrimary,
                              ),
                              columns: const [
                                DataColumn(label: Text('No')),
                                DataColumn(label: Text('Nama')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Peran')),
                              ],
                              rows: List.generate(organizers.length, (index) {
                                final o = organizers[index];
                                final profile = o['profiles'] as Map<String, dynamic>?;
                                final isCreator = profile != null && o['user_id'] == _event.createdBy;
                                return DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        profile?['full_name'] ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        profile?['email'] ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCreator
                                            ? AppColors.primary.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCreator ? 'Pembuat' : 'Co-Panitia',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isCreator ? AppColors.primary : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]);
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () => _showAccessCodePopup(),
                    leading: Icon(Icons.vpn_key_outlined, color: context.textPrimary, size: 22),
                    title: const Text('Ganti Kode Akses', style: TextStyle(fontSize: 14)),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 20),
                  ListTile(
                    onTap: () => _showAksiPopup(),
                    leading: Icon(Icons.more_horiz_rounded, color: context.textPrimary, size: 22),
                    title: const Text('Aksi', style: TextStyle(fontSize: 14)),
                    trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                  ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(_event),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.softBlue,
                        size: 20,
                      ),
                      label: const Text(
                        'Keluar dari Kelola Event',
                        style: TextStyle(
                          color: AppColors.softBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.softBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

class _AssetCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String placeholder;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _AssetCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.placeholder,
    required this.buttonLabel,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: context.bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentBlue,
                  width: 1.5,
                ),
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
                backgroundColor: AppColors.accentBlue,
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
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
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
}

class _QrDialogWidget extends StatefulWidget {
  final Event event;
  const _QrDialogWidget({required this.event});

  @override
  State<_QrDialogWidget> createState() => _QrDialogWidgetState();
}

class _QrDialogWidgetState extends State<_QrDialogWidget> {
  Timer? _timer;
  late String _qrData;
  int _secondsLeft = 5;
  late final bool _hasQrSecret;

  @override
  void initState() {
    super.initState();
    _hasQrSecret = widget.event.qrSecret != null;

    if (_hasQrSecret) {
      _qrData = EventService.generateQrData(widget.event.id, widget.event.qrSecret!);
      _secondsLeft = 5 - (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 5;
      if (_secondsLeft <= 0) _secondsLeft = 5;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final msLeft = EventService.msUntilNextRefresh();
        final secLeft = (msLeft ~/ 1000) + 1;

        if (secLeft != _secondsLeft || msLeft < 100) {
          setState(() {
            _secondsLeft = secLeft;
            _qrData = EventService.generateQrData(
              widget.event.id,
              widget.event.qrSecret!,
            );
          });
        } else {
          setState(() => _secondsLeft = secLeft);
        }
      });
    } else {
      _qrData = widget.event.id;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Absensi Event',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              QrImageView(
                data: _qrData,
                size: 250,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              if (_hasQrSecret)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: _secondsLeft / 5,
                        color: AppColors.accentBlue,
                        backgroundColor: AppColors.accentBlue.withOpacity(0.15),
                      ),
                    ),
                    const SizedBox(width: 8),
                  Text(
                    'Refresh dalam $_secondsLeft detik',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tunjukkan QR ini ke peserta untuk absen',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
        );
      },
    );
  }
}
