import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../main.dart' show supabase;
import 'event_access_screen.dart';
import 'event_manage_screen.dart';
import '../widgets/screen_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final userId = supabase.auth.currentUser?.id;
    _eventsFuture = userId != null
        ? EventService.fetchMyEvents(userId)
        : Future.value([]);
  }

  Future<void> _refresh() async {
    setState(_loadEvents);
    await _eventsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Dashboard',
                  subtitle: 'Event yang kamu buat atau kelola',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: FutureBuilder<List<Event>>(
                  future: _eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text(
                              'Kamu belum membuat event apapun',
                              style: TextStyle(
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _DashboardEventCard(
                          event: events[index],
                          onEventUpdated: _refresh,
                        ),
                        childCount: events.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEventUpdated;
  const _DashboardEventCard({
    required this.event,
    required this.onEventUpdated,
  });

  bool get _isActive => event.status == 'active';
  bool get _isRejected => event.status == 'rejected';

  String get _statusLabel {
    switch (event.status) {
      case 'pending':
        return 'Menunggu persetujuan';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return 'Aktif';
    }
  }

  Color get _statusColor {
    if (_isActive) return AppColors.primary;
    if (_isRejected) return Colors.red.shade300;
    return AppColors.lightTextSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final greyedOut = !_isActive;

    return Opacity(
      opacity: greyedOut ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: greyedOut ? Colors.black12 : Colors.transparent,
          ),
          boxShadow: greyedOut
              ? []
              : [
                  BoxShadow(
                    color: context.shadowColor(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.organizerName,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
            if (event.status == 'rejected' &&
                event.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan: ${event.rejectionReason}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_isActive)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () async {
                    final acceptedEvent = await showAccessCodeDialog(
                      context,
                      event,
                    );
                    if (acceptedEvent == null || !context.mounted) return;
                    final updatedEvent = await Navigator.push<Event>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventManageScreen(event: acceptedEvent),
                      ),
                    );
                    if (updatedEvent != null) {
                      onEventUpdated();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Masuk & Kelola Event',
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
    );
  }
}
