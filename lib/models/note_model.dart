import 'key_model.dart';

class NoteModel {
  final String id;
  final String userId;
  final String? title;
  final String? description;
  final String? imageUrl;
  final List<KeyLink>? links;
  final bool isPinned;
  final String? conversationId;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.userId,
    this.title,
    this.description,
    this.imageUrl,
    this.links,
    this.isPinned = false,
    this.conversationId,
    required this.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      links: (json['links'] as List?)?.map((e) => KeyLink.fromJson(e)).toList(),
      isPinned: json['is_pinned'] ?? false,
      conversationId: json['conversation_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final res = {
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'links': links?.map((e) => e.toJson()).toList(),
      'is_pinned': isPinned,
      'conversation_id': conversationId,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) res['id'] = id;
    return res;
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? imageUrl,
    List<KeyLink>? links,
    bool? isPinned,
    String? conversationId,
    DateTime? createdAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      links: links ?? this.links,
      isPinned: isPinned ?? this.isPinned,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
