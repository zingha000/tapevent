enum NotificationType { eventNearby, recommendation, admin }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });
}

/// Data contoh untuk sementara. Nanti digantikan data real dari aplikasi:
/// - jadwal event yang semakin dekat
/// - rekomendasi event berdasarkan minat
/// - info admin (event disetujui/ditolak)
List<AppNotification> buildDummyNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      type: NotificationType.admin,
      title: 'Event Anda Disetujui',
      message:
          'Event "Festival Teknologi 2026" telah disetujui oleh admin dan sekarang tampil di beranda TapEvent.',
      createdAt: now.subtract(const Duration(minutes: 8)),
      read: false,
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.eventNearby,
      title: 'Event Dimulai Besok',
      message:
          'Workshop "UI/UX Design Essentials" akan berlangsung besok pukul 09.00 di Gedung Kuliah Umum A.',
      createdAt: now.subtract(const Duration(hours: 2)),
      read: false,
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.recommendation,
      title: 'Rekomendasi untuk Kamu',
      message:
          'Berdasarkan event yang sering kamu sukai, coba lihat "Lomba Startup Campus 2026" yang mungkin kamu suka.',
      createdAt: now.subtract(const Duration(hours: 5)),
      read: false,
    ),
    AppNotification(
      id: 'n4',
      type: NotificationType.admin,
      title: 'Event Ditolak',
      message:
          'Mohon maaf, event "Konser Amal Mahasiswa" belum dapat disetujui. Periksa kembali kelengkapan berkas pendaftaran.',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      read: true,
    ),
    AppNotification(
      id: 'n5',
      type: NotificationType.eventNearby,
      title: 'Event Akan Segera Mulai',
      message:
          'Seminar "Karier di Dunia Digital" dimulai dalam 30 menit. Jangan lupa check-in di lokasi acara.',
      createdAt: now.subtract(const Duration(hours: 8)),
      read: true,
    ),
    AppNotification(
      id: 'n6',
      type: NotificationType.recommendation,
      title: 'Event Baru di Kampus',
      message:
          'Ada event baru "Turnamen Badminton Kampus" yang mungkin sesuai dengan minatmu.',
      createdAt: now.subtract(const Duration(days: 2)),
      read: true,
    ),
    AppNotification(
      id: 'n7',
      type: NotificationType.admin,
      title: 'Selamat Datang di TapEvent',
      message:
          'Akunmu berhasil dibuat. Lengkapi profil kamu untuk pengalaman yang lebih baik.',
      createdAt: now.subtract(const Duration(days: 5)),
      read: true,
    ),
  ];
}
