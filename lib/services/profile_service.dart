import '../main.dart' show supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show supabase;

class ProfileService {
  static Future<Map<String, dynamic>?> fetchMyProfile(String userId) async {
    final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    return data;
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> fields) async {
    await supabase.from('profiles').update(fields).eq('id', userId);
  }

  static Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}