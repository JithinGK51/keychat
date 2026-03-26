import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChatStyle { glass, bubble, minimal }

final styleProvider = StateNotifierProvider<StyleNotifier, ChatStyle>((ref) {
  return StyleNotifier();
});

class StyleNotifier extends StateNotifier<ChatStyle> {
  StyleNotifier() : super(ChatStyle.glass) {
    _loadStyle();
  }

  static const String _key = 'chat_style';

  Future<void> _loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleIndex = prefs.getInt(_key);
    if (styleIndex != null) {
      state = ChatStyle.values[styleIndex];
    }
  }

  Future<void> setStyle(ChatStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, state.index);
  }
}
