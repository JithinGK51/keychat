import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/auth_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _reset() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      NotificationHelper.error(context, "Password must be at least 6 characters.");
      return;
    }
    if (password != _confirmPasswordController.text.trim()) {
      NotificationHelper.error(context, "Passwords do not match.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: password,
      ).timeout(const Duration(seconds: 15));
      
      if (mounted) {
        NotificationHelper.success(context, "Your password has been securely updated.", title: "Success");
        Navigator.of(context).popUntil((route) => route.isFirst);
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
                  center: Alignment(-0.8, 0.6),
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
                      'Reset Vault Access',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    Text(
                      'SECURE YOUR ACCOUNT WITH A NEW PASSWORD',
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
                            controller: _passwordController,
                            hint: 'New Password',
                            icon: HeroIcons.lockClosed,
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: 'Confirm Password',
                            icon: HeroIcons.lockClosed,
                          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _reset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 15,
                                shadowColor: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'UPDATE PASSWORD',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
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
        obscureText: true,
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
