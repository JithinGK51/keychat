import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});
