import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) {
  return LockNotifier();
});

class LockState {
  final bool isEnabled;
  final String? pin;
  final bool isLocked;

  LockState({this.isEnabled = false, this.pin, this.isLocked = false});

  LockState copyWith({bool? isEnabled, String? pin, bool? isLocked}) {
    return LockState(
      isEnabled: isEnabled ?? this.isEnabled,
      pin: pin ?? this.pin,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(LockState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('lock_enabled') ?? false;
    final pin = prefs.getString('lock_pin');
    state = LockState(isEnabled: isEnabled, pin: pin, isLocked: isEnabled);
  }

  Future<void> setLock(bool enabled, String? pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lock_enabled', enabled);
    if (pin != null) await prefs.setString('lock_pin', pin);
    state = state.copyWith(isEnabled: enabled, pin: pin, isLocked: enabled);
  }

  void unlock(String pin) {
    if (state.pin == pin) {
      state = state.copyWith(isLocked: false);
    }
  }

  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }
}
