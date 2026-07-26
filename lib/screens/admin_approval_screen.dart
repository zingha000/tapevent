import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;
import 'admin_approval_history_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  late Future<List<Event>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _pendingFuture = EventService.fetchPendingEvents();
  }

  Future<void> _approve(Event event) async {
    final adminId = supabase.auth.currentUser?.id;
    if (adminId == null) return;
    await EventService.approveEvent(event.id, adminId);
    if (!mounted) return;
    setState(_load);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${event.title} disetujui')),
    );
  }

  Future<void> _reject(Event event) async {
    final reasonController = TextEditingController();

    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tolak Event',
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
                    margin: const EdgeInsets.symmetric(horizontal: 28),
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
                        Text('Tolak "${event.title}"',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Jelaskan alasan penolakan event ini:',
                            style: TextStyle(fontSize: 13, color: context.textSecondary)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: Bukti pengesahan tidak sesuai',
                            filled: true,
                            fillColor: context.secondaryBg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.border),
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
                                    side: BorderSide(color: context.border),
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
                                  child: const Text('Tolak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      final adminId = supabase.auth.currentUser?.id;
      if (adminId == null) return;
      await EventService.rejectEvent(event.id, adminId, reasonController.text.trim());
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${event.title} ditolak')),
      );
    }
  }

  void _viewProof(String? url) {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti tidak tersedia')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(url, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF62440), Color(0xFFD81336), Color(0xFFB80E2C)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApprovalHistoryScreen()));
                        },
                        child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Persetujuan Event',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tinjau dan setujui event yang diajukan oleh penyelenggara',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _pendingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return Center(
                    child: Text('Tidak ada event yang menunggu persetujuan', style: TextStyle(color: context.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: context.shadowColor(0.06), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 110,
                            width: double.infinity,
                            color: AppColors.sand,
                            child: event.bannerUrl != null
                                ? Image.network(event.bannerUrl!, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.image_outlined, size: 28, color: Colors.white70)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
                                const SizedBox(height: 4),
                                Text(event.organizerName, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                Text(
                                  '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _viewProof(event.proofDocumentUrl),
                                    icon: Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
                                    label: const Text('Lihat Bukti', style: TextStyle(color: AppColors.primary)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _reject(event),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Tolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approve(event),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
