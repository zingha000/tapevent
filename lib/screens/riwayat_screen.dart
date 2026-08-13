import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/profile_service.dart';
import '../theme/app_colors.dart';
import '../main.dart' show supabase;
import 'event_detail_screen.dart';
import '../widgets/screen_header.dart';
import '../widgets/lottie_loading.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<Event>> _historyFuture;
  Future<Map<String, dynamic>?>? _profileFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = supabase.auth.currentUser?.id;
    _historyFuture = userId != null
        ? EventService.fetchMyHistory(userId)
        : Future.value([]);
    _profileFuture = userId != null
        ? ProfileService.fetchMyProfile(userId)
        : Future.value(null);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _historyFuture;
    await _profileFuture;
  }

  Future<void> _downloadHistory(List<Event> events, String name) async {
    if (events.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada riwayat event untuk diunduh')),
      );
      return;
    }

    final rows = <List<String>>[
      ['No', 'Nama Event', 'Penyelenggara', 'Tanggal', 'Status'],
    ];
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final start =
          '${e.startDate!.day}/${e.startDate!.month}/${e.startDate!.year}';
      final end = e.endDate != null
          ? '${e.endDate!.day}/${e.endDate!.month}/${e.endDate!.year}'
          : '-';
      rows.add([
        '${i + 1}',
        e.title,
        e.organizerName,
        '$start - $end',
        'Selesai',
      ]);
    }

    final csv = const CsvEncoder().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/riwayat_event_$name.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Riwayat Event - $name'),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageScaffoldColor,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ScreenHeader(
                          title: 'Riwayat',
                          subtitle: 'Event yang pernah kamu ikuti',
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: context.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (v) => setState(
                                      () => _query = v.toLowerCase(),
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Cari event yang pernah diikuti...',
                                      hintStyle: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 13,
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
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snap) {
                            final name =
                                (snap.data?['full_name'] as String?) ??
                                supabase
                                        .auth
                                        .currentUser
                                        ?.userMetadata?['full_name']
                                    as String? ??
                                'Pengguna';
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: context.cardDecoration,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '👋 ',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  'Hai, $name',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: context.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          FutureBuilder<List<Event>>(
                                            future: _historyFuture,
                                            builder: (context, snap2) {
                                              final count =
                                                  snap2.data?.length ?? 0;
                                              return Text(
                                                'Kamu telah mengikuti $count event yang selesai',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.textSecondary,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 42,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final events = await _historyFuture;
                                          if (!mounted) return;
                                          _downloadHistory(events, name);
                                        },
                                        icon: const Icon(
                                          Icons.download_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Unduh',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accentBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: FutureBuilder<List<Event>>(
                      future: _historyFuture,
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
                        final events = (snapshot.data ?? [])
                            .where(
                              (e) => e.title.toLowerCase().contains(_query),
                            )
                            .toList();
                        if (events.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 40,
                                    color: context.textSecondary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Belum ada event yang selesai diikuti',
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
                            (context, index) =>
                                _HistoryCard(event: events[index]),
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

class _HistoryCard extends StatelessWidget {
  final Event event;
  const _HistoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: context.surface,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentPink, AppColors.accentBlue],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -15,
                        right: -10,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -8,
                        left: -8,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      if (event.bannerUrl != null)
                        Image.network(
                          event.bannerUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.history_rounded,
                            size: 32,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.organizerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
