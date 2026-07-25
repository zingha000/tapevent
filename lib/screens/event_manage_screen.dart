import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../main.dart' show supabase;
import 'event_edit_screen.dart';
import '../services/event_service.dart';

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
  bool _uploadingCsv = false;
  late Future<List<Map<String, dynamic>>> _participantsFuture;

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
                      boxShadow: [BoxShadow(color: context.shadowColor(0.15), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Hapus Event',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Tindakan ini tidak bisa dibatalkan. Jelaskan alasan penghapusan:',
                            style: TextStyle(fontSize: 13, color: context.textSecondary)),
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
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
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
                                  onPressed: () => Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: Text('Batal', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (reasonController.text.trim().isEmpty) return;
                                    Navigator.of(context).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil dihapus')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus event')),
        );
      }
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
                      color: context.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QR Absensi Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
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
                            color: context.textSecondary,
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
                      boxShadow: [BoxShadow(color: context.shadowColor(0.15), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hapus ${profile?['full_name'] ?? 'Peserta'}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Jelaskan alasan penghapusan peserta ini:',
                            style: TextStyle(fontSize: 13, color: context.textSecondary)),
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
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
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
                                  onPressed: () => Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                   child: Text('Batal', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (reasonController.text.trim().isEmpty) return;
                                    Navigator.of(context).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      await EventService.dropParticipant(participant['id'], reasonController.text.trim());
      if (!mounted) return;
      setState(() => _participantsFuture = EventService.fetchParticipants(_event.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Peserta berhasil dihapus')));
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
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
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
        backgroundColor: context.bg,
        appBar: AppBar(
          title: Text(_event.title, overflow: TextOverflow.ellipsis),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
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
                      color: context.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

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

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daftar Peserta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
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
                                color: AppColors.primary,
                              ),
                        label: Text(
                          _uploadingCsv ? 'Memproses...' : 'Upload CSV',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: baris pertama header, kolom pertama = NIM/NIP',
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
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final participants = snapshot.data ?? [];
                      if (participants.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Belum ada peserta terdaftar',
                              style: TextStyle(
                                color: context.textSecondary,
                              ),
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
                                              onPressed: () => _respondCancellation(p),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.orange),
                                                foregroundColor: Colors.orange,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Tanggapi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            )
                                          : OutlinedButton(
                                              onPressed: () => _dropParticipant(p),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.red),
                                                foregroundColor: Colors.red,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () =>
                        setState(() => _showAccessCode = !_showAccessCode),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.vpn_key_outlined,
                            size: 18,
                            color: context.textPrimary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ganti Kode Akses',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            _showAccessCode
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: context.textSecondary,
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
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kode Akses Saat Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
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

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      label: const Text(
                        'Hapus Event',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'https://drive.google.com/...',
            filled: true,
            fillColor: context.surface,
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
