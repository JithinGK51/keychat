import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../services/auth_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/theme.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const VerifyOtpScreen({super.key, required this.email, this.isPasswordReset = false});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _verify() async {
    if (_otpController.text.length < 6) {
      NotificationHelper.error(context, "Please enter the full 6-digit code.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      if (widget.isPasswordReset) {
        // Just navigate to reset password screen with the OTP
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              otp: _otpController.text.trim(),
            ),
          ),
        );
      } else {
        await _authService.verifyOtp(
          email: widget.email,
          otp: _otpController.text.trim(),
        ).timeout(const Duration(seconds: 15));
        
        if (mounted) {
          NotificationHelper.success(context, "Identity confirmed! You can now log in.", title: "Verified");
          Navigator.of(context).popUntil((route) => route.isFirst);
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
                  center: Alignment(0.8, 0.6),
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
                        HeroIcons.shieldCheck,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: Offset(0.8, 0.8)).shimmer(delay: 1.seconds),
                    const SizedBox(height: 32),
                    Text(
                      'Security Shield',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 12),
                    Text(
                      'WE SENT A CODE TO\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
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
                          _buildOtpField().animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'VERIFY IDENTITY',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: Offset(0.95, 0.95)),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entered wrong email? Go back', style: TextStyle(color: AppColors.primary)),
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

  Widget _buildOtpField() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 12,
        color: AppColors.primary,
      ),
      decoration: InputDecoration(
        counterText: "",
        hintText: "000000",
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }
}
