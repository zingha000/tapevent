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
import '../widgets/search_field.dart';

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
            child: Image.asset(
              'assets/images/bg1_home.png',
              fit: BoxFit.cover,
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
                      child: SearchField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _query = v.toLowerCase()),
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

  // Soft badge colors (light bg + dark text), matching the Free/Paid badge.
  (Color, Color) get _statusColors {
    switch (event.status) {
      case 'pending':
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
      case 'rejected':
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      case 'completed':
        return (const Color(0xFFFEF3C7), const Color(0xFFB45309));
      default:
        return (const Color(0xFFDCFCE7), const Color(0xFF15803D));
    }
  }

  Future<void> _openManage(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final greyedOut = !_isActive;
    final (badgeBg, badgeFg) = _statusColors;

    return GestureDetector(
      onTap: _isActive ? () => _openManage(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 118,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.global),
          border: Border.all(
            color: greyedOut ? Colors.black12 : AppColors.border,
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // ─── Banner Image (wider, left) ───
            SizedBox(
              width: 150,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.bannerUrl != null)
                    Image.network(event.bannerUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      color: context.secondaryBg,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Gradient overlay so the status label stays readable
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status label — top right corner of the photo
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.inner),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ),
                ],
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
                    // Title beside date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: greyedOut
                                  ? context.textSecondary
                                  : context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          AppIcons.calendar,
                          size: 12,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Pengelola
                    Text(
                      'Pengelola: ${event.organizerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),

                    if (_isRejected && event.rejectionReason != null) ...[
                      const SizedBox(height: 3),
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
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () => _openManage(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.inner,
                                ),
                              ),
                            ),
                          child: const Text(
                            'Kelola event',
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
