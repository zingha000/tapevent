import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;
import 'qr_scan_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _myRegistration;
  bool _loadingRegistration = true;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loadingRegistration = false);
      return;
    }
    final reg = await EventService.fetchMyRegistration(widget.event.id, userId);
    if (!mounted) return;
    setState(() {
      _myRegistration = reg;
      _loadingRegistration = false;
    });
  }

  Future<void> _requestCancellation() async {
    final reasonController = TextEditingController();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Ajukan Batal',
      barrierColor: Colors.black.withValues(alpha: 0.3),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ajukan Pembatalan',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Panitia akan meninjau pengajuan ini. Jelaskan alasanmu:',
                            style: TextStyle(fontSize: 13, color: context.textSecondary)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Berhalangan hadir karena...',
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
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
                                    backgroundColor: Colors.orange,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Ajukan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await EventService.requestCancellation(widget.event.id, userId, reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan pembatalan berhasil dikirim')),
      );
      _checkRegistration();
    }
  }

  Future<void> _openRegistrationForm(BuildContext context) async {
    final url = widget.event.registrationFormUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulir pendaftaran belum tersedia')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka tautan')),
      );
    }
  }

  void _openDocCert(String? url, String label) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tautan')),
        );
      }
    } else if (context.mounted) {
      _showNotReadyPopup(label);
    }
  }

  void _showNotReadyPopup(String label) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: label,
      barrierColor: Colors.black.withValues(alpha: 0.3),
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
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.hourglass_empty_rounded, color: Colors.orange, size: 28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$label Belum Tersedia',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label == 'Sertifikat'
                              ? 'Panitia belum selesai menyiapkan sertifikatnya, nih. Mohon bersabar ya.'
                              : 'Dokumentasi masih dalam proses upload, nih. Mohon bersabar ya.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageScaffoldColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.accentBlue,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      final link = 'https://tapevent.com/event/${widget.event.id}';
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link event disalin')),
                      );
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.event.bannerUrl != null
                      ? Image.network(widget.event.bannerUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.accentPink, AppColors.accentBlue],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 48, color: Colors.white70),
                          ),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black38],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: context.border, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // ─── Header: Title → Tagline → Jenis ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      if (widget.event.tagline != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.event.tagline!,
                          style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.4),
                        ),
                      ],
                      if (widget.event.category != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.event.category!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                      if (!_loadingRegistration &&
                          _myRegistration != null &&
                          _myRegistration!['cancellation_requested'] != true) ...[
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScanScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.accentBlue,
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Scan Absen',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Info Section: Jadwal → Lokasi → Penyelenggara → Contact → Kuota ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Column(
                      children: [
                      _InfoRow(
                        icon: AppIcons.calendar,
                        label: 'Jadwal',
                        value: widget.event.endDate != null
                            ? '${_formatDate(widget.event.startDate)} - ${_formatDate(widget.event.endDate!)}'
                            : _formatDate(widget.event.startDate),
                      ),
                      if (widget.event.location != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: widget.event.location!,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.groups_outlined,
                        label: 'Penyelenggara',
                        value: widget.event.organizerName,
                      ),
                      if (widget.event.contactPerson != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Contact Person',
                          value: widget.event.contactPerson!,
                        ),
                      ],
                      if (widget.event.maxParticipants != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.people_alt_outlined,
                          label: 'Kuota Peserta',
                          value: '${widget.event.participantCount} / ${widget.event.maxParticipants}',
                        ),
                      ],
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 20),

                // ─── Dokumentasi & Sertifikat (hanya untuk completed) ───
                if (widget.event.status == 'completed') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DocCertButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Dokumentasi',
                            onPressed: () => _openDocCert(
                              widget.event.documentationUrl,
                              'Dokumentasi',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DocCertButton(
                            icon: Icons.verified_outlined,
                            label: 'Sertifikat',
                            onPressed: () => _openDocCert(
                              widget.event.certificateUrl,
                              'Sertifikat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ─── Description ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
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
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          width: double.infinity,
                          alignment: Alignment.topLeft,
                          child: SingleChildScrollView(
                            child: Text(
                              widget.event.description ?? 'Belum ada deskripsi.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Action Buttons ───
                if (widget.event.status != 'completed')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (!_loadingRegistration && _myRegistration == null) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _openRegistrationForm(context),
                              icon: const Icon(Icons.edit_document, color: Colors.white, size: 20),
                              label: const Text(
                                'Formulir Pendaftaran',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Akan membuka Google Form di luar aplikasi',
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                          ),
                        ],

                        if (!_loadingRegistration && _myRegistration != null) ...[
                          const SizedBox(height: 12),
                          if (_myRegistration!['cancellation_requested'] == true)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'Menunggu persetujuan panitia',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _requestCancellation,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.orange),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Ajukan Batal', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],

                        if (_loadingRegistration) ...[
                          const SizedBox(height: 8),
                          const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocCertButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DocCertButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
    );
  }
}