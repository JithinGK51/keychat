import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.client;
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android Emulator

  // Sign Up via Backend
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw data['detail'] ?? 'Registration failed';
    }
    return data;
  }

  // Verify OTP
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw data['detail'] ?? 'Verification failed';
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw data['detail'] ?? 'Login failed';
    }

    if (data['status'] == 'verification_required') {
      return {'status': 'verification_required', 'email': email};
    }

    // Handle token/session if needed (e.g., store in secure storage)
    // For now, we'll assume the app manages its own state or uses Supabase for sessions
    // If the backend returns a token, we should use it.
    
    return {'status': 'success', 'user': data['user']};
  }

  // Forgot Password Request
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': '', // Empty password as it's just for request
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw data['detail'] ?? 'Forgot password request failed';
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw data['detail'] ?? 'Password reset failed';
    }
  }

  // Ensure Bucket exists via Backend
  Future<void> ensureBucket(String email) async {
    final encodedEmail = Uri.encodeComponent(email);
    try {
      await http.post(Uri.parse('$baseUrl/auth/ensure-bucket/$encodedEmail'));
    } catch (e) {
      debugPrint('DEBUG: ensureBucket error: $e');
    }
  }

  // Get Profile Data
  Future<Map<String, dynamic>> getProfile(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile/$email'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    final data = json.decode(response.body);
    if (response.statusCode != 200) {
      throw data['detail'] ?? 'Failed to fetch profile';
    }
    return data;
  }

  // Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Update Password (after reset or from profile)
  Future<void> updatePassword(String newPassword) async {
    // This could also be a backend call if we want to manage it there
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Update User Metadata — syncs to Supabase profiles table via backend
  Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    // Use email passed in data OR fall back to Supabase currentUser (for Supabase-auth users)
    final email = data['email'] as String? ?? currentUser?.email;
    if (email == null) {
      debugPrint('DEBUG: updateUserMetadata — no email available, skipping update');
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': data['name'],
          'profile_image': data['profile_image'],
        }),
      ).timeout(const Duration(seconds: 15));
      debugPrint('DEBUG: updateUserMetadata — profile updated for $email');
    } catch (e) {
      debugPrint('DEBUG: updateProfile error: $e');
    }
  }

  // Get current session
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
