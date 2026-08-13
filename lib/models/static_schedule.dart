// Data jadwal statis untuk preview (sementara belum ada input/output).
// Nanti diganti dengan jadwal pengguna dari backend.

class StaticScheduleEvent {
  final DateTime date;
  final String title;
  final String organizer;
  final String category;

  const StaticScheduleEvent({
    required this.date,
    required this.title,
    required this.organizer,
    required this.category,
  });
}

List<StaticScheduleEvent> staticScheduleEvents(DateTime now) {
  final base = DateTime(now.year, now.month, now.day);
  return [
    StaticScheduleEvent(
      date: base.add(const Duration(days: 1)),
      title: 'Seminar Digitalisasi Pendidikan',
      organizer: 'BEM Fakultas Teknik',
      category: 'Seminar',
    ),
    StaticScheduleEvent(
      date: base.add(const Duration(days: 5)),
      title: 'Lomba Desain Poster Nasional',
      organizer: 'UKM Seni & Desain',
      category: 'Lomba',
    ),
    StaticScheduleEvent(
      date: base.add(const Duration(days: 9)),
      title: 'Workshop Public Speaking',
      organizer: 'Himpunan Mahasiswa Ilmu Komunikasi',
      category: 'Workshop',
    ),
  ];
}

List<DateTime> staticScheduleEventDates(DateTime now) =>
    staticScheduleEvents(now).map((e) => e.date).toList();
