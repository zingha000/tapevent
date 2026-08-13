import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import 'event_detail_screen.dart';
import 'event_create_screen.dart';
import '../widgets/lottie_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<List<Event>> _eventsFuture;
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    _eventsFuture = EventService.fetchActiveEvents();
  }

  Future<void> refresh() async {
    setState(_load);
    await _eventsFuture;
  }

  List<Event> _filterEvents(List<Event> events) {
    return events.where((e) {
      final matchQuery =
          _query.isEmpty ||
          e.title.toLowerCase().contains(_query) ||
          e.organizerName.toLowerCase().contains(_query) ||
          (e.category ?? '').toLowerCase().contains(_query) ||
          (e.tagline ?? '').toLowerCase().contains(_query);
      final matchCategory =
          _selectedCategory == null ||
          _selectedCategory == 'Semua' ||
          (e.category ?? '').toLowerCase() == _selectedCategory!.toLowerCase();
      return matchQuery && matchCategory;
    }).toList();
  }

  Widget _buildTerpopulerSection() {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final all = _filterEvents(snapshot.data!);
        if (all.isEmpty) return const SizedBox.shrink();
        final popular = List<Event>.from(all)
          ..sort((a, b) => b.participantCount.compareTo(a.participantCount));
        final top = popular.take(3).toList();
        return SizedBox(
          height: _EventCard.heightFor(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(28, 0, 20, 0),
            clipBehavior: Clip.none,
            itemCount: top.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: _EventCard.widthFor(context),
              child: _EventCard(event: top[index]),
            ),
          ),
        );
      },
    );
  }

  void _showAllEventsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllEventsSheet(
        eventsFuture: _eventsFuture,
        filterEvents: _filterEvents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg1_home.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _HomeHeaderDelegate(
                      searchController: _searchController,
                      onSearchChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EventCreateScreen(),
                            ),
                          );
                          if (result == true && context.mounted) {
                            refresh();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF62440),
                                Color(0xFFB80E2C),
                                Color(0xFF6C1D8F),
                                Color(0xFF3B3FAF),
                              ],
                              stops: [0.0, 0.35, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Buat Event Saya',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Buat event menarik bersama teman-teman mahasiswa',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 60,
                                height: 60,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Image.asset(
                                  'assets/images/calender.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ─── Category Filter ───
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _CategoryFilter(
                      selected: _selectedCategory,
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Event Terpopuler'),
                  ),
                  // Terpopuler: horizontal scroll, top by participantCount
                  SliverToBoxAdapter(child: _buildTerpopulerSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Semua Event',
                      actionText: 'Lihat Semua',
                      onAction: () => _showAllEventsSheet(context),
                    ),
                  ),
                  // Semua Event: max 4 cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
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
                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  'Gagal memuat event: ${snapshot.error}',
                                ),
                              ),
                            ),
                          );
                        }
                        final allEvents = snapshot.data ?? [];
                        final events = _filterEvents(allEvents);
                        if (events.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 40,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    allEvents.isEmpty
                                        ? 'Belum ada event aktif saat ini'
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
                        final displayed = events.take(4).toList();
                        return SliverList.separated(
                          itemCount: displayed.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              _EventCard(event: displayed[index]),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  // ─── Design tokens ───
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color hairline = Color(0xFFF1F5F9);
  static const double _bannerAspectRatio = 2.6;
  static const double _padding = 12;
  // Fixed height of everything below the banner (padding + typography + spacing).
  // Intentionally a touch larger than the sum of children so the fixed-height
  // horizontal list never overflows.
  static const double _contentHeight = 158;

  static double widthFor(BuildContext context) =>
      MediaQuery.of(context).size.width - 56;

  static double bannerHeightFor(BuildContext context) =>
      widthFor(context) / _bannerAspectRatio;

  static double heightFor(BuildContext context) =>
      bannerHeightFor(context) + _contentHeight;

  String _formatDate(DateTime start, DateTime? end) {
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
    String dayLabel(DateTime d) =>
        '${d.day} ${months[d.month - 1].toLowerCase()}';
    return end != null
        ? '${dayLabel(start)} - ${dayLabel(end)} ${end.year}'
        : '${dayLabel(start)} ${start.year}';
  }

  Color get _categoryColor {
    switch ((event.category ?? '').toLowerCase()) {
      case 'workshop':
        return const Color(0xFFE97A2B);
      case 'seminar':
        return const Color(0xFF3B82F6);
      case 'lomba':
        return const Color(0xFF8B5CF6);
      case 'olahraga':
        return const Color(0xFF22C55E);
      case 'sosial':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = context.isDark ? context.textPrimary : ink;
    final subtitleColor = context.isDark ? context.textSecondary : muted;
    final dividerColor = context.isDark ? context.border : hairline;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Banner (compact, AspectRatio 2.5) ───
            AspectRatio(
              aspectRatio: _bannerAspectRatio,
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
                          size: 32,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  // Subtle bottom gradient for depth
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category badge — top left (small pill)
                  if (event.category != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _categoryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event.category!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _categoryColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Content (12h/12b padding, extra top gap after banner) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _padding,
                14,
                _padding,
                _padding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Free/Paid badge (sejajar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Tagline — 11px italic, di bawah judul
                  SizedBox(
                    height: 14.3,
                    width: double.infinity,
                    child: (event.tagline != null && event.tagline!.isNotEmpty)
                        ? Text(
                            event.tagline!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: subtitleColor,
                              height: 1.3,
                            ),
                          )
                        : null,
                  ),
                  // Spasi lebih untuk memisahkan bagian tanggal
                  const SizedBox(height: 10),
                  Container(height: 1, color: dividerColor),
                  const SizedBox(height: 10),
                  // Date + Organizer (penerbit) — sejajar
                  Row(
                    children: [
                      Icon(
                        AppIcons.calendar,
                        size: 14,
                        color: subtitleColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 6,
                        child: Text(
                          _formatDate(event.startDate, event.endDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.business_center_rounded,
                              size: 14,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.organizerName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: subtitleColor,
                                  height: 1.3,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: dividerColor),
                  const SizedBox(height: 8),
                  // Footer — bulat-bulat peserta + button Lihat Detail
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 22,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: _avatarDot(context),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  child: _avatarDot(context),
                                ),
                                Positioned(
                                  left: 16,
                                  top: 0,
                                  child: _avatarDot(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              '${event.participantCount} peserta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
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
    );
  }

  Widget _avatarDot(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: context.surface, width: 1.5),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: context.border, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllEventsSheet extends StatelessWidget {
  final Future<List<Event>> eventsFuture;
  final List<Event> Function(List<Event>) filterEvents;

  const _AllEventsSheet({
    required this.eventsFuture,
    required this.filterEvents,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Semua Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.textSecondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: FutureBuilder<List<Event>>(
                  future: eventsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LottieLoading());
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Tidak ada data'));
                    }
                    final events = filterEvents(snapshot.data!);
                    if (events.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 36,
                              color: context.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada event yang cocok',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _EventCard(event: events[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  static const _categories = [
    {'label': 'Semua', 'icon': Icons.grid_view_rounded, 'color': null},
    {
      'label': 'Workshop',
      'icon': Icons.build_rounded,
      'color': Color(0xFFE97A2B),
    },
    {'label': 'Seminar', 'icon': Icons.mic_rounded, 'color': Color(0xFF3B82F6)},
    {
      'label': 'Lomba',
      'icon': Icons.emoji_events_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'label': 'Olahraga',
      'icon': Icons.sports_soccer_rounded,
      'color': Color(0xFF22C55E),
    },
    {
      'label': 'Sosial',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isActive =
              (selected == null && cat['label'] == 'Semua') ||
              selected == cat['label'];
          final color = cat['color'] as Color?;

          return GestureDetector(
            onTap: () => onSelected(isActive ? null : cat['label'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? (color ?? AppColors.primary)
                    : context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? (color ?? AppColors.primary)
                      : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 15,
                    color: isActive ? Colors.white : context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.searchController,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  double get minExtent => 116;

  @override
  double get maxExtent => 208;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(28),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 6 * progress,
                  sigmaY: 6 * progress,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.surface.withValues(alpha: 0.72 * progress),
                    border: Border(
                      bottom: BorderSide(
                        color: context.border,
                        width: progress > 0 ? 1 : 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeaderContent(
              searchController: searchController,
              onSearchChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HomeHeaderDelegate oldDelegate) =>
      oldDelegate.searchController != searchController ||
      oldDelegate.onSearchChanged != onSearchChanged;
}

class _HeaderContent extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _HeaderContent({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 176,
                height: 92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo_horizontal.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Temukan dan ikuti event kampusmu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1D),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.search,
                  color: context.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1D1D1D),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari event...',
                      hintStyle: TextStyle(
                        color: context.textSecondary,
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
        ],
      ),
    );
  }
}
