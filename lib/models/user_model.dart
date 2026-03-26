class UserModel {
  final String id;
  final String? name;
  final String email;
  final String? profileImage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.name,
    required this.email,
    this.profileImage,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
