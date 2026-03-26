import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/note_model.dart';
import '../../services/supabase_service.dart';
import 'user_provider.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final Ref ref;
  NotesNotifier(this.ref) : super([]);

  final _client = SupabaseService.client;
  RealtimeChannel? _channel;

  Future<void> fetchNotes(String? conversationId) async {
    final user = ref.read(userProvider);
    if (user == null) return;
    final userId = user.id;

    var query = _client.from('notes').select().eq('user_id', userId);
    
    if (conversationId != null) {
      query = query.eq('conversation_id', conversationId);
    } else {
      query = query.isFilter('conversation_id', null);
    }

    _channel?.unsubscribe();
    
    final response = await query.order('created_at', ascending: true);
    state = (response as List).map((e) => NoteModel.fromJson(e)).toList();
    
    _setupRealtime(userId, conversationId);
  }

  void _setupRealtime(String userId, String? conversationId) {
    var filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'user_id',
      value: userId,
    );

    _channel = _client.channel('public:notes:${conversationId ?? "default"}');
    
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: filter,
          callback: (payload) {
            final noteId = payload.eventType == PostgresChangeEvent.delete 
                ? payload.oldRecord['id'] 
                : payload.newRecord['id'];
            
            // Validate conversation_id match
            final payloadConvId = payload.eventType == PostgresChangeEvent.delete 
                ? null // Can't easily check for deletes without more data, but we filter by userId
                : payload.newRecord['conversation_id'];

            if (payload.eventType != PostgresChangeEvent.delete && payloadConvId != conversationId) return;

            if (payload.eventType == PostgresChangeEvent.insert) {
              final newNote = NoteModel.fromJson(payload.newRecord);
              if (!state.any((n) => n.id == newNote.id)) {
                state = [...state, newNote];
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              state = state.where((n) => n.id != noteId).toList();
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final updated = NoteModel.fromJson(payload.newRecord);
              state = state.map((n) => n.id == updated.id ? updated : n).toList();
            }
          },
        )
        .subscribe();
  }

  Future<void> addNote(NoteModel note, String? conversationId) async {
    try {
      final data = note.toJson();
      data['conversation_id'] = conversationId;
      final response = await _client.from('notes').insert(data).select().single();
      final newNote = NoteModel.fromJson(response);
      if (!state.any((n) => n.id == newNote.id)) {
        state = [...state, newNote];
      }
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  Future<void> togglePin(NoteModel note) async {
    await _client.from('notes').update({'is_pinned': !note.isPinned}).eq('id', note.id);
  }

  Future<void> updateNote(String id, String title, String description) async {
    await _client.from('notes').update({
      'title': title,
      'description': description,
    }).eq('id', id);
  }

  void clearLocalNotes() {
    state = [];
  }
}
