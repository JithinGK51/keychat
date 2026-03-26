import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/auth_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/theme.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      NotificationHelper.error(context, "Please enter your email.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      await _authService.forgotPassword(email).timeout(const Duration(seconds: 15));
      if (mounted) {
        NotificationHelper.success(context, "A password recovery code has been sent to your email.", title: "Recovery Code");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(email: email, isPasswordReset: true),
          ),
        );
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.8, -0.6),
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E1B4B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: HeroIcon(
                        HeroIcons.key,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: Offset(0.8, 0.8)),
                    const SizedBox(height: 32),
                    Text(
                      'Recover Vault',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    Text(
                      "WE'LL SEND YOU A SECURE RECOVERY CODE",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Recovery Email',
                            icon: HeroIcons.envelope,
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'SEND RECOVERY CODE',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
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
