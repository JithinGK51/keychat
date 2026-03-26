import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/theme.dart';
import 'forgot_password_screen.dart';
import 'verify_otp_screen.dart';
import '../home/home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      NotificationHelper.error(context, "Please enter your email address.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final result = await _authService.login(
          email: email,
          password: _passwordController.text.trim(),
        );
        
        if (mounted) {
          if (result['status'] == 'verification_required') {
            NotificationHelper.show(context, title: "Verify Account", message: "A verification code has been sent to your email.");
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VerifyOtpScreen(email: email)),
            );
          } else {
            // Save user data to local provider + SharedPreferences
            final user = result['user'] as Map<String, dynamic>?;
            if (user != null) {
              await ref.read(userProvider.notifier).setUser(user);
            }
            if (mounted) {
              NotificationHelper.success(context, "Welcome back! Accessing your secure notes.");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      } else {
        await _authService.signUp(
          email: email,
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
        if (mounted) {
          NotificationHelper.success(context, "Registration successful! Check your email for a verification code.", title: "Code Sent");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VerifyOtpScreen(email: email)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.error(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.6),
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E1B4B), // Deep Indigo
                    Color(0xFF0F172A), // Slate
                  ],
                ),
              ),
            ),
          ),
          // Animated Background Orbs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(duration: 4.seconds, curve: Curves.easeInOut).then().scale(duration: 4.seconds, begin: const Offset(1, 1), end: const Offset(0.8, 0.8)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: HeroIcon(
                        HeroIcons.commandLine,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2).shimmer(delay: 1.seconds),
                    const SizedBox(height: 32),
                    // Heading
                    Text(
                      _isLogin ? 'KeyNote' : 'Secure Join',
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    Text(
                      _isLogin ? 'FUTURISTIC NOTE SYNC' : 'START YOUR ENCRYPTED JOURNEY',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 48),
                    // Glassmorphic Form
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: HeroIcons.user,
                            ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                            const SizedBox(height: 20),
                          ],
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: HeroIcons.envelope,
                          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: HeroIcons.lockClosed,
                            isPassword: true,
                          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),
                          if (_isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shadowColor: AppColors.primary.withValues(alpha: 0.5),
                                elevation: 15,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      _isLogin ? 'ACCESS VAULT' : 'CREATE ACCOUNT',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 1.seconds).scale(begin: const Offset(0.9, 0.9)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).scale(begin: Offset(0.95, 0.95)),
                    const SizedBox(height: 32),
                    // Toggle Mode
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                          children: [
                            TextSpan(text: _isLogin ? "Don't have an account? " : "Already verified? "),
                            TextSpan(
                              text: _isLogin ? "SIGN UP" : "LOG IN",
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 1.2.seconds),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required HeroIcons icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HeroIcon(icon, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
