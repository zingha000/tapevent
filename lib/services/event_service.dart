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
}