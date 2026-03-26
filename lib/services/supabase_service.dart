import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://vnobrapudgnhnvzkkrab.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZub2JyYXB1ZGduaG52emtrcmFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMTA0NTIsImV4cCI6MjA4OTg4NjQ1Mn0.q-3IULt7CNb1v1ZPl-Ko-56DjT51RDQUiHXhOmEcPiY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
