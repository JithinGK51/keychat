import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/conversation_model.dart';
import '../services/auth_service.dart';
import 'user_provider.dart';

class ConversationState {
  final List<ConversationModel> conversations;
  final String? activeConversationId;
  final bool isLoading;

  ConversationState({
    this.conversations = const [],
    this.activeConversationId,
    this.isLoading = false,
  });

  ConversationState copyWith({
    List<ConversationModel>? conversations,
    String? activeConversationId,
    bool? isLoading,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(ref);
});

class ConversationNotifier extends StateNotifier<ConversationState> {
  final Ref ref;
  ConversationNotifier(this.ref) : super(ConversationState());

  static const String _baseUrl = 'http://10.0.2.2:8000';

  Future<void> fetchConversations() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/conversations/${user.id}'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final list = data.map((e) => ConversationModel.fromJson(e)).toList();
        state = state.copyWith(
          conversations: list,
          activeConversationId: state.activeConversationId ?? (list.isNotEmpty ? list.first.id : null),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createConversation({String? title}) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.id,
          'title': title ?? 'New Chat',
        }),
      );

      if (response.statusCode == 200) {
        final newConv = ConversationModel.fromJson(jsonDecode(response.body));
        state = state.copyWith(
          conversations: [newConv, ...state.conversations],
          activeConversationId: newConv.id,
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  void setActiveConversation(String id) {
    state = state.copyWith(activeConversationId: id);
  }

  Future<void> deleteConversation(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/conversations/$id'));
      if (response.statusCode == 200) {
        state = state.copyWith(
          conversations: state.conversations.where((c) => c.id != id).toList(),
          activeConversationId: state.activeConversationId == id ? (state.conversations.isNotEmpty ? state.conversations.first.id : null) : state.activeConversationId,
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> clearActiveChat() async {
    final activeId = state.activeConversationId;
    try {
      final url = activeId == null 
          ? '$_baseUrl/conversations/clear/default?user_id=${AuthService().currentUser?.id}'
          : '$_baseUrl/conversations/clear/$activeId';
          
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        // Success
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> renameConversation(String id, String newTitle) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/conversations/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': newTitle}),
      );
      if (response.statusCode == 200) {
        state = state.copyWith(
          conversations: state.conversations.map((c) => c.id == id ? c.copyWith(title: newTitle) : c).toList(),
        );
      }
    } catch (e) {
      // Handle error
    }
  }
}
