class KeyLink {
  final String title;
  final String url;

  KeyLink({required this.title, required this.url});

  factory KeyLink.fromJson(Map<String, dynamic> json) {
    return KeyLink(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
}

class KeyModel {
  final String id;
  final String userId;
  final String keyName;
  final String? title;
  final String? description;
  final String? imageUrl;
  final List<KeyLink>? links;
  final bool isFavorite;
  final DateTime createdAt;

  KeyModel({
    required this.id,
    required this.userId,
    required this.keyName,
    this.title,
    this.description,
    this.imageUrl,
    this.links,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory KeyModel.fromJson(Map<String, dynamic> json) {
    return KeyModel(
      id: json['id'],
      userId: json['user_id'],
      keyName: json['key_name'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      links: (json['links'] as List?)?.map((e) => KeyLink.fromJson(e)).toList(),
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final res = {
      'user_id': userId,
      'key_name': keyName,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'links': links?.map((e) => e.toJson()).toList(),
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) res['id'] = id;
    return res;
  }
}
