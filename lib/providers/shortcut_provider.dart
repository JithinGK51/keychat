import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/key_model.dart';
import '../../services/supabase_service.dart';
import 'user_provider.dart';

final shortcutProvider = StateNotifierProvider<ShortcutNotifier, List<KeyModel>>((ref) {
  return ShortcutNotifier(ref);
});

class ShortcutNotifier extends StateNotifier<List<KeyModel>> {
  final Ref _ref;
  ShortcutNotifier(this._ref) : super([]);

  final _client = SupabaseService.client;

  Future<void> fetchKeys() async {
    final user = _ref.read(userProvider);
    if (user == null || user.id.isEmpty || user.id == "null") return;
    final userId = user.id;

    try {
      final response = await _client
          .from('keys')
          .select()
          .eq('user_id', userId)
          .order('is_favorite', ascending: false)
          .order('created_at', ascending: false);
      
      state = (response as List).map((e) => KeyModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching keys: $e');
    }
  }

  Future<void> addKey(KeyModel key) async {
    if (key.userId.isEmpty || key.userId == "null") {
      debugPrint('Error: Attempted to add key with invalid userId: ${key.userId}');
      return;
    }
    
    try {
      final response = await _client
          .from('keys')
          .insert(key.toJson())
          .select()
          .single();
      
      final newKey = KeyModel.fromJson(response);
      state = [newKey, ...state];
    } catch (e) {
      debugPrint('Error adding key: $e');
    }
  }

  Future<void> deleteKey(String id) async {
    try {
      await _client.from('keys').delete().eq('id', id);
      state = state.where((k) => k.id != id).toList();
    } catch (e) {
      debugPrint('Error deleting key: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final key = state.firstWhere((k) => k.id == id);
      final response = await _client
          .from('keys')
          .update({'is_favorite': !key.isFavorite})
          .eq('id', id)
          .select()
          .single();
      
      final updatedKey = KeyModel.fromJson(response);
      state = state.map((k) => k.id == id ? updatedKey : k).toList();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  List<KeyModel> searchKeys(String query) {
    if (query.isEmpty) return state;
    final lowercaseQuery = query.toLowerCase();
    return state.where((k) => 
      k.keyName.toLowerCase().contains(lowercaseQuery) ||
      (k.title?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  KeyModel? expandKey(String input) {
    if (!input.startsWith('/')) return null;
    final keyName = input.substring(1).toLowerCase();
    try {
      return state.firstWhere((k) => k.keyName.toLowerCase() == keyName);
    } catch (_) {
      return null;
    }
  }
}
