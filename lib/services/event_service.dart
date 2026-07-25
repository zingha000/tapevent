import '../models/event.dart';
import '../main.dart' show supabase;

class EventService {
  /// Ambil semua event dengan status 'active', diurutkan dari tanggal terdekat.
  static Future<List<Event>> fetchActiveEvents() async {
    final data = await supabase
        .from('events')
        .select()
        .eq('status', 'active')
        .order('start_date', ascending: true);

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }
  static Future<List<Event>> fetchMyEvents(String userId) async {
    final data = await supabase
        .from('events')
        .select()
        .eq('created_by', userId)
        .neq('status', 'deleted')
        .order('created_at', ascending: false);

    return (data as List).map((json) => Event.fromJson(json)).toList();
  }
  /// Buat event baru, status otomatis 'pending' menunggu approval admin.
  static Future<void> createEvent({
    required String title,
    String? tagline,
    String? description,
    String? bannerUrl,
    String? category,
    required DateTime startDate,
    DateTime? endDate,
    required String organizerName,
    String? contactPerson,
    String? registrationFormUrl,
    String? proofDocumentUrl,
    required String createdBy,
  }) async {
    await supabase.from('events').insert({
      'title': title,
      'tagline': tagline,
      'description': description,
      'banner_url': bannerUrl,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'organizer_name': organizerName,
      'contact_person': contactPerson,
      'registration_form_url': registrationFormUrl,
      'proof_document_url': proofDocumentUrl,
      'created_by': createdBy,
    });
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
  /// Ambil event yang sudah selesai dan diikuti oleh user (lewat registrations).
  static Future<List<Event>> fetchMyHistory(String userId) async {
    final data = await supabase
        .from('registrations')
        .select('events(*)')
        .eq('user_id', userId)
        .eq('events.status', 'completed');

    return (data as List)
        .where((row) => row['events'] != null)
        .map((row) => Event.fromJson(row['events']))
        .toList();
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
          .map((p) => {'event_id': eventId, 'user_id': p['id']})
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
}