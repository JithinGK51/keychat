import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

/// Simple model for the logged-in user (since we use custom backend auth,
/// Supabase currentUser is always null — we persist user data ourselves).
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? profileImage;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
  });

  AppUser copyWith({String? name, String? profileImage}) => AppUser(
        id: id,
        email: email,
        name: name ?? this.name,
        profileImage: profileImage ?? this.profileImage,
      );
}

class UserNotifier extends StateNotifier<AppUser?> {
  static const _keyId = 'user_id';
  static const _keyEmail = 'user_email';
  static const _keyName = 'user_name';
  static const _keyProfileImage = 'user_profile_image';
  final _authService = AuthService();

  UserNotifier() : super(null) {
    _loadFromPrefs();
  }

  /// Load persisted user on app start and sync with backend
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final id = prefs.getString(_keyId);
    if (email != null && id != null) {
      state = AppUser(
        id: id,
        email: email,
        name: prefs.getString(_keyName) ?? '',
        profileImage: prefs.getString(_keyProfileImage),
      );
      // Sync with backend asynchronously
      syncProfile(email);
    }
  }

  /// Save user to state and persistence
  Future<void> setUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final id = userData['id']?.toString();
    final email = userData['email']?.toString();
    final name = userData['name']?.toString() ?? '';
    if (id == null || email == null) return;
    final profileImage = userData['profile_image']?.toString();

    await prefs.setString(_keyId, id);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    if (profileImage != null) {
      await prefs.setString(_keyProfileImage, profileImage);
    } else {
      await prefs.remove(_keyProfileImage);
    }

    state = AppUser(id: id, email: email, name: name, profileImage: profileImage);
  }

  /// Update name locally after profile update
  Future<void> updateName(String name) async {
    if (state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    state = state!.copyWith(name: name);
  }

  /// Update profile image URL locally after upload
  Future<void> updateProfileImage(String url) async {
    if (state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImage, url);
    state = state!.copyWith(profileImage: url);
  }

  /// Call on logout — clears all persisted data
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyProfileImage);
    state = null;
  }

  /// Fetch latest data from Supabase via backend
  Future<void> syncProfile(String email) async {
    try {
      final profile = await _authService.getProfile(email);
      final id = profile['id']?.toString();
      if (id == null) return;
      final name = profile['name'] ?? '';
      final profileImage = profile['profile_image'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyId, id);
      await prefs.setString(_keyName, name);
      if (profileImage != null) {
        await prefs.setString(_keyProfileImage, profileImage);
      } else {
        await prefs.remove(_keyProfileImage);
      }
      
      state = AppUser(id: id, email: email, name: name, profileImage: profileImage);
    } catch (e) {
      // Keep local state if sync fails
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AppUser?>(
  (ref) => UserNotifier(),
);
