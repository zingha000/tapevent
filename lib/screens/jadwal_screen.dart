import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../models/static_schedule.dart';

class JadwalScreen extends StatefulWidget {
  final bool showBackButton;
  const JadwalScreen({super.key, this.showBackButton = false});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late final List<StaticScheduleEvent> _events;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedDate = now;
    _events = staticScheduleEvents(now);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
  }

  List<StaticScheduleEvent> _eventsOn(DateTime date) {
    return _events.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ScreenHeader(
                  title: 'Jadwal',
                  subtitle: 'Preview jadwal event yang kamu ikuti',
                  showBackButton: widget.showBackButton,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _CalendarCard(
                    displayedMonth: _displayedMonth,
                    selectedDate: _selectedDate,
                    eventDates: _events.map((e) => e.date).toList(),
                    onMonthChanged: _changeMonth,
                    onDateSelected: (d) => setState(() => _selectedDate = d),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    'Jadwal Tanggal Terpilih',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _SelectedDateEvents(
                    events: _eventsOn(_selectedDate),
                    date: _selectedDate,
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Keterangan tanggal terpilih ───
class _SelectedDateEvents extends StatelessWidget {
  final List<StaticScheduleEvent> events;
  final DateTime date;

  const _SelectedDateEvents({required this.events, required this.date});

  static const _months = [
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

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: context.cardDecoration,
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 32,
                  color: context.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada event pada tanggal ini',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _EventInfoCard(event: events[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  final StaticScheduleEvent event;
  const _EventInfoCard({required this.event});

  Color get _categoryColor {
    switch (event.category.toLowerCase()) {
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: context.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentPink, AppColors.accentBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
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
                      event.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.organizer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
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
    );
  }
}

// ─── Kalender besar ───
class _CalendarCard extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<DateTime> eventDates;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarCard({
    required this.displayedMonth,
    required this.selectedDate,
    required this.eventDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  static const _weekdays = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];

  static const _months = [
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

  bool _hasEvent(DateTime date) {
    return eventDates.any(
      (e) =>
          e.year == date.year &&
          e.month == date.month &&
          e.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final firstWeekday = DateTime(year, month).weekday; // 1=Sen..7=Min
    final leadingBlanks = firstWeekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final isSameMonth = today.year == year && today.month == month;

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = isSameMonth && today.day == day;
      final isSelected =
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day;
      final hasEvent = _hasEvent(date);
      final isWeekend = date.weekday == 6 || date.weekday == 7;

      cells.add(
        GestureDetector(
          onTap: () => onDateSelected(date),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isWeekend
                            ? context.textSecondary
                            : context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasEvent ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onMonthChanged(-1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.secondaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[month - 1]} $year',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onMonthChanged(1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.secondaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final wd in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      wd,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            children: cells,
          ),
        ],
      ),
    );
  }
}


