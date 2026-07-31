import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/event.dart';
import '../main.dart' show supabase;

class EventService {
  /// Ambil semua event dengan status 'active', diurutkan dari tanggal terdekat.
  /// Event yang sudah lewat end_date difilter secara otomatis.
  /// Participant count diambil dari tabel registrations.
  static Future<List<Event>> fetchActiveEvents() async {
    final data = await supabase
        .from('events')
        .select()
        .eq('status', 'active')
        .order('start_date', ascending: true);

    final now = DateTime.now().toUtc();
    final events = (data as List)
        .map((json) => Event.fromJson(json))
        .where((e) =>
            e.endDate == null ||
            e.endDate!.toUtc().isAfter(now))
        .toList();

    return _attachParticipantCounts(events);
  }

  /// Ambil semua event yang bisa dikelola (semua event active/pending),
  /// biar panitia lain bisa lihat dan join lewat kode akses.
  static Future<List<Event>> fetchMyEvents(String userId) async {
    final data = await supabase
        .from('events')
        .select()
        .neq('status', 'deleted')
        .neq('status', 'completed')
        .order('created_at', ascending: false);

    return _attachParticipantCounts(
      (data as List).map((j) => Event.fromJson(j)).toList(),
    );
  }

  /// Hitung jumlah registrasi aktif (non-dropped) untuk setiap event.
  static Future<List<Event>> _attachParticipantCounts(List<Event> events) async {
    if (events.isEmpty) return events;
    final eventIds = events.map((e) => e.id).toList();

    final counts = await supabase
        .from('registrations')
        .select('event_id')
        .inFilter('event_id', eventIds)
        .eq('is_dropped', false);

    final Map<String, int> countMap = {};
    for (final row in counts as List) {
      final eid = row['event_id'] as String;
      countMap[eid] = (countMap[eid] ?? 0) + 1;
    }

    return events.map((e) => e.copyWith(participantCount: countMap[e.id] ?? 0)).toList();
  }

  /// Buat event baru, status otomatis 'pending' menunggu approval admin.
  static Future<Event> createEvent({
    required String title,
    String? tagline,
    String? description,
    String? bannerUrl,
    String? category,
    required DateTime startDate,
    DateTime? endDate,
    int? maxParticipants,
    String? location,
    required String organizerName,
    String? contactPerson,
    String? registrationFormUrl,
    String? proofDocumentUrl,
    required String createdBy,
  }) async {
    final data = await supabase.from('events').insert({
      'title': title,
      'tagline': tagline,
      'description': description,
      'banner_url': bannerUrl,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_participants': maxParticipants,
      if (location != null) 'location': location,
      'organizer_name': organizerName,
      'contact_person': contactPerson,
      'registration_form_url': registrationFormUrl,
      'proof_document_url': proofDocumentUrl,
      'created_by': createdBy,
      'qr_secret': _generateQrSecret(),
      'status': 'pending',
      'access_code': _generateRandomCode(),
    }).select().single() as Map<String, dynamic>;
    return Event.fromJson(data);
  }

  /// Update field apa saja pada event (dipakai untuk edit judul, deskripsi, banner, dst)
  static Future<void> updateEvent(String eventId, Map<String, dynamic> fields) async {
    await supabase.from('events').update(fields).eq('id', eventId);
  }

  /// Soft delete: event tidak dihapus fisik, cuma ditandai status 'deleted' + alasan.
  static Future<void> deleteEvent(String eventId, String reason) async {
    await supabase.from('events').update({
      'status': 'deleted',
      'deletion_reason': reason,
    }).eq('id', eventId);
  }

  /// Tandai event sebagai 'completed' (selesai).
  static Future<void> completeEvent(String eventId) async {
    final result = await supabase.from('events').update({
      'status': 'completed',
    }).eq('id', eventId).select();
    if (result.isEmpty) {
      throw Exception('Gagal menyelesaikan event');
    }
  }

  /// Tandai semua event active yang sudah lewat end_date menjadi 'completed'.
  static Future<void> autoCompleteExpiredEvents() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await supabase
        .from('events')
        .update({'status': 'completed'})
        .eq('status', 'active')
        .not('end_date', 'is', null)
        .lte('end_date', now);
  }

  /// Ambil event yang sudah selesai: yang diikuti (lewat registrations) DAN yang dibuat oleh user.
  static Future<List<Event>> fetchMyHistory(String userId) async {
    // 1. Event yang diikuti (via registrations)
    final joinedData = await supabase
        .from('registrations')
        .select('events(*)')
        .eq('user_id', userId)
        .eq('events.status', 'completed');

    final joinedEvents = (joinedData as List)
        .where((row) => row['events'] != null)
        .map((row) => Event.fromJson(row['events']))
        .toList();

    // 2. Event yang dibuat oleh user (status completed)
    final createdData = await supabase
        .from('events')
        .select()
        .eq('created_by', userId)
        .eq('status', 'completed');

    final createdEvents = (createdData as List)
        .map((json) => Event.fromJson(json))
        .toList();

    // Gabung & deduplicate
    final seen = <String>{};
    final all = <Event>[];
    for (final e in [...joinedEvents, ...createdEvents]) {
      if (seen.add(e.id)) all.add(e);
    }
    all.sort((a, b) => b.startDate.compareTo(a.startDate));
    return all;
  }

  /// Cocokkan daftar NIM dari CSV ke profiles, insert ke registrations.
  /// Return: {matched: jumlah berhasil, unmatched: List NIM yang tidak ditemukan}
  static Future<Map<String, dynamic>> uploadParticipants(String eventId, List<String> nims) async {
    final cleanNims = nims.map((n) => n.trim()).where((n) => n.isNotEmpty).toSet().toList();

    final matchedProfiles = await supabase
        .from('profiles')
        .select('id, identity_number')
        .inFilter('identity_number', cleanNims);

    final matchedList = matchedProfiles as List;
    final matchedNims = matchedList.map((p) => p['identity_number'] as String).toSet();
    final unmatched = cleanNims.where((n) => !matchedNims.contains(n)).toList();

    if (matchedList.isNotEmpty) {
      final rows = matchedList
          .map((p) => {
                'event_id': eventId,
                'user_id': p['id'],
                'is_dropped': false,
                'dropped_reason': null,
              })
          .toList();
      await supabase.from('registrations').upsert(rows, onConflict: 'event_id,user_id');
    }

    return {'matched': matchedList.length, 'unmatched': unmatched};
  }

  /// Ambil daftar peserta terdaftar di suatu event, lengkap dengan status hadir.
  static Future<List<Map<String, dynamic>>> fetchParticipants(String eventId) async {
    final data = await supabase
        .from('registrations')
        .select('id, is_dropped, cancellation_requested, cancellation_reason, profiles(full_name, identity_number), attendances(scanned_at)')
        .eq('event_id', eventId)
        .eq('is_dropped', false)
        .order('registered_at');

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Panitia hapus/drop peserta secara sepihak.
  static Future<void> dropParticipant(String registrationId, String reason) async {
    await supabase.from('registrations').update({
      'is_dropped': true,
      'dropped_reason': reason,
    }).eq('id', registrationId);
  }

  /// Peserta mengajukan pembatalan, menunggu persetujuan panitia.
  static Future<void> requestCancellation(String eventId, String userId, String reason) async {
    await supabase.from('registrations').update({
      'cancellation_requested': true,
      'cancellation_reason': reason,
    }).eq('event_id', eventId).eq('user_id', userId);
  }

  /// Panitia menyetujui pembatalan — peserta resmi keluar (is_dropped = true).
  static Future<void> approveCancellation(String registrationId, String reason) async {
    await supabase.from('registrations').update({
      'is_dropped': true,
      'dropped_reason': reason,
      'cancellation_requested': false,
    }).eq('id', registrationId);
  }

  /// Panitia menolak pembatalan — peserta tetap terdaftar normal.
  static Future<void> rejectCancellation(String registrationId) async {
    await supabase.from('registrations').update({
      'cancellation_requested': false,
      'cancellation_reason': null,
    }).eq('id', registrationId);
  }

  /// Cek apakah user tertentu sudah terdaftar di event tertentu (buat munculin tombol Ajukan Batal).
  static Future<Map<String, dynamic>?> fetchMyRegistration(String eventId, String userId) async {
    return await supabase
        .from('registrations')
        .select()
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .eq('is_dropped', false)
        .maybeSingle();
  }

  /// Generate kode akses baru untuk event (misal kode lama bocor/disalahgunakan).
  static Future<String> regenerateAccessCode(String eventId) async {
    final newCode = _generateRandomCode();
    await supabase.from('events').update({'access_code': newCode}).eq('id', eventId);
    return newCode;
  }

  static String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random ~/ (i + 3)) % chars.length]).join();
  }

  /// Generate random 16-char secret untuk QR token.
  static String _generateQrSecret() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(16, (i) => chars[(random ~/ (i + 2)) % chars.length]).join();
  }

  /// Generate dynamic QR token: HMAC-SHA256(eventId:qrSecret:timeSlot).
  /// QR data format: "eventId:token:timeSlot"
  static String generateQrData(String eventId, String qrSecret) {
    final timeSlot = DateTime.now().millisecondsSinceEpoch ~/ 5000;
    final payload = '$eventId:$qrSecret:$timeSlot';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    final token = digest.toString().substring(0, 32);
    return '$eventId:$token:$timeSlot';
  }

  /// Get current time slot for countdown display.
  static int getCurrentTimeSlot() => DateTime.now().millisecondsSinceEpoch ~/ 5000;

  /// Get milliseconds until next QR refresh.
  static int msUntilNextRefresh() => 5000 - (DateTime.now().millisecondsSinceEpoch % 5000);

  /// Validate QR token on server side.
  /// Return: {success: bool, message: String}
  static Future<Map<String, dynamic>> checkInAttendance(
    String scannedEventId,
    String userId, {
    required String token,
    required int timeSlot,
  }) async {
    // 1. Fetch qr_secret for this event
    final eventData = await supabase
        .from('events')
        .select('qr_secret')
        .eq('id', scannedEventId)
        .maybeSingle();

    if (eventData == null || eventData['qr_secret'] == null) {
      return {'success': false, 'message': 'Event tidak ditemukan'};
    }

    final qrSecret = eventData['qr_secret'] as String;

    // 2. Validate timeSlot (tolerance: ±1 slot = ±5 seconds)
    final currentSlot = DateTime.now().millisecondsSinceEpoch ~/ 5000;
    if ((currentSlot - timeSlot).abs() > 1) {
      return {'success': false, 'message': 'QR sudah kedaluwarsa, minta QR baru'};
    }

    // 3. Validate token
    final expectedPayload = '$scannedEventId:$qrSecret:$timeSlot';
    final expectedBytes = utf8.encode(expectedPayload);
    final expectedDigest = sha256.convert(expectedBytes);
    final expectedToken = expectedDigest.toString().substring(0, 32);

    if (token != expectedToken) {
      return {'success': false, 'message': 'QR tidak valid'};
    }

    // 4. Check registration
    final registration = await supabase
        .from('registrations')
        .select('id')
        .eq('event_id', scannedEventId)
        .eq('user_id', userId)
        .eq('is_dropped', false)
        .maybeSingle();

    if (registration == null) {
      return {'success': false, 'message': 'Kamu tidak terdaftar di event ini'};
    }

    final registrationId = registration['id'];

    // 5. Check duplicate attendance
    final existingAttendance = await supabase
        .from('attendances')
        .select('id')
        .eq('registration_id', registrationId)
        .maybeSingle();

    if (existingAttendance != null) {
      return {'success': false, 'message': 'Kamu sudah absen sebelumnya'};
    }

    // 6. Record attendance
    await supabase.from('attendances').insert({
      'registration_id': registrationId,
      'scanned_by': userId,
    });

    return {'success': true, 'message': 'Absensi berhasil dicatat'};
  }

  /// Catat user yang berhasil masuk lewat kode akses (termasuk pembuat event).
  /// Tidak dobel kalau orang yang sama sudah pernah tercatat.
  static Future<void> recordOrganizerAccess(String eventId, String userId) async {
    final existing = await supabase
        .from('event_organizers')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      try {
        await supabase.from('event_organizers').insert({
          'event_id': eventId,
          'user_id': userId,
        });
      } catch (_) {
        // Insert gagal (misal race condition duplicate key), abaikan saja.
      }
    }
  }

  /// Ambil daftar semua orang yang tercatat pernah masuk Kelola Event ini.
  static Future<List<Map<String, dynamic>>> fetchOrganizers(String eventId) async {
    final data = await supabase
        .from('event_organizers')
        .select('id, joined_at, profiles(full_name, email)')
        .eq('event_id', eventId)
        .order('joined_at');

    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Ambil semua event dengan status 'pending' untuk ditinjau admin.
  static Future<List<Event>> fetchPendingEvents() async {
    final data = await supabase
        .from('events')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List).map((json) => Event.fromJson(json)).toList();
  }

  /// Hitung jumlah event pending, untuk badge notifikasi di halaman Saya.
  static Future<int> countPendingEvents() async {
    final data = await supabase.from('events').select('id').eq('status', 'pending');
    return (data as List).length;
  }

  /// Admin menyetujui event.
  static Future<void> approveEvent(String eventId, String adminId) async {
    final error = await supabase.from('events').update({
      'status': 'active',
      'approved_by': adminId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId).select();
    if (error.isEmpty) {
      throw Exception('Gagal menyetujui event. Pastikan policy RLS sudah benar.');
    }
  }

  /// Admin menolak event, wajib beri alasan.
  static Future<void> rejectEvent(String eventId, String adminId, String reason) async {
    final error = await supabase.from('events').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'approved_by': adminId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', eventId).select();
    if (error.isEmpty) {
      throw Exception('Gagal menolak event. Pastikan policy RLS sudah benar.');
    }
  }

  /// Riwayat semua event yang sudah pernah diproses admin (disetujui/ditolak).
  static Future<List<Map<String, dynamic>>> fetchApprovalHistory() async {
    final data = await supabase
        .from('events')
        .select('id, title, organizer_name, status, created_at, rejection_reason, created_by')
        .inFilter('status', ['active', 'rejected'])
        .order('created_at', ascending: false);
    final list = (data as List).cast<Map<String, dynamic>>();

    // Resolve full_name for each unique created_by
    final userIds = list.map((e) => e['created_by'] as String).where((id) => id.isNotEmpty).toSet().toList();
    if (userIds.isNotEmpty) {
      final profiles = await supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);
      final nameMap = {
        for (final p in (profiles as List)) p['id'] as String: p['full_name'] as String? ?? '-'
      };
      for (final item in list) {
        item['profiles'] = {'full_name': nameMap[item['created_by']] ?? '-'};
      }
    }
    return list;
  }
}
