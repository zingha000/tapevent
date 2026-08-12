import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../main.dart' show supabase;
import 'event_access_screen.dart';
import 'event_manage_screen.dart';
import '../widgets/screen_header.dart';
import '../widgets/lottie_loading.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Event>> _eventsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, 150),
              child: Image.asset(
                'assets/images/bg1_home.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ScreenHeader(
                      title: 'Dashboard',
                      subtitle: 'Event yang kamu buat atau kelola',
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(
                              Icons.search_rounded,
                              color: Colors.grey.shade500,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _query = v.toLowerCase()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1D),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari event...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    sliver: FutureBuilder<List<Event>>(
                      future: _eventsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: LottieLoading(),
                                ),
                              ),
                            ),
                          );
                        }
                        final allEvents = snapshot.data ?? [];
                        final events = allEvents.where((e) {
                          if (_query.isEmpty) return true;
                          return e.title.toLowerCase().contains(_query) ||
                              e.organizerName.toLowerCase().contains(_query) ||
                              (e.category ?? '').toLowerCase().contains(_query);
                        }).toList();
                        if (events.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.dashboard_rounded,
                                    size: 40,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    allEvents.isEmpty
                                        ? 'Kamu belum membuat event apapun'
                                        : 'Tidak ada event yang cocok',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
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
        ],
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
        return 'Menunggu';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return 'Aktif';
    }
  }

  Color get _statusColor {
    if (_isActive) return AppColors.success;
    if (_isRejected) return AppColors.error;
    if (event.status == 'completed') return AppColors.sand;
    return AppColors.lightTextSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final greyedOut = !_isActive;

    return GestureDetector(
      onTap: _isActive
          ? () async {
              final acceptedEvent = await showAccessCodeDialog(context, event);
              if (acceptedEvent == null || !context.mounted) return;
              final updatedEvent = await Navigator.push<Event>(
                context,
                MaterialPageRoute(
                  builder: (_) => EventManageScreen(event: acceptedEvent),
                ),
              );
              if (updatedEvent != null) onEventUpdated();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 130,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: greyedOut ? Colors.black12 : AppColors.border,
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // ─── Banner Image (left, full height) ───
            SizedBox(
              width: 130,
              height: double.infinity,
              child: event.bannerUrl != null
                  ? Image.network(event.bannerUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x00fff2db),
                            Color(0x00ffe5bf),
                            Color(0x00fffaf3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.white70,
                        ),
                      ),
                    ),
            ),

            // ─── Divider ───
            Container(width: 1, color: AppColors.border),

            // ─── Content (right side) ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          AppIcons.calendar,
                          size: 12,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: greyedOut
                            ? context.textSecondary
                            : context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Organizer
                    Text(
                      event.organizerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),

                    if (_isRejected && event.rejectionReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.rejectionReason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Button
                    if (_isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () async {
                            final acceptedEvent = await showAccessCodeDialog(
                              context,
                              event,
                            );
                            if (acceptedEvent == null || !context.mounted)
                              return;
                            final updatedEvent = await Navigator.push<Event>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventManageScreen(event: acceptedEvent),
                              ),
                            );
                            if (updatedEvent != null) onEventUpdated();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Kelola',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
