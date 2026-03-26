class ConversationModel {
  final String id;
  final String userId;
  final String? title;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.userId,
    this.title,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
