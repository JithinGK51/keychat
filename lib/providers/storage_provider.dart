import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class StorageInfo {
  final int usedBytes;
  final int totalBytes;
  final double percentage;

  StorageInfo({required this.usedBytes, required this.totalBytes, required this.percentage});

  factory StorageInfo.fromJson(Map<String, dynamic> json) {
    return StorageInfo(
      usedBytes: json['used_bytes'],
      totalBytes: json['total_bytes'],
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

final storageProvider = StateNotifierProvider<StorageNotifier, AsyncValue<StorageInfo>>((ref) {
  return StorageNotifier();
});

class StorageNotifier extends StateNotifier<AsyncValue<StorageInfo>> {
  StorageNotifier() : super(const AsyncValue.loading());

  Future<void> fetchUsage() async {
    final email = AuthService().currentUser?.email;
    if (email == null) return;

    try {
      // Use 10.0.2.2 for Android Emulator
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/auth/storage-usage/$email'));
      if (response.statusCode == 200) {
        state = AsyncValue.data(StorageInfo.fromJson(jsonDecode(response.body)));
      } else {
        state = AsyncValue.error('Failed to load storage info', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
