import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/supabase_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/lock_provider.dart';
import 'screens/auth/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(
    const ProviderScope(
      child: KeyChatApp(),
    ),
  );
}

class KeyChatApp extends ConsumerWidget {
  const KeyChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'KeyNote Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    // Diagnostic logging
    debugPrint('DEBUG: AuthWrapper building. authState: ${authState.value?.event}');

    return authState.when(
      data: (data) {
        if (data.session != null) {
          debugPrint('DEBUG: Session found. Showing HomeScreen.');
          final lockState = ref.watch(lockProvider);
          if (lockState.isLocked) {
            return const PinLockScreen();
          }
          return const HomeScreen();
        } else {
          debugPrint('DEBUG: No session. Showing AuthScreen.');
          return const AuthScreen();
        }
      },
      loading: () {
        debugPrint('DEBUG: AuthState loading...');
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stack) {
        debugPrint('DEBUG: AuthState error: $error');
        return const AuthScreen();
      },
    );
  }
}
