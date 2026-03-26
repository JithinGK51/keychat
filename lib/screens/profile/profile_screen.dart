import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/storage_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/upload_service.dart';
import '../../utils/notification_helper.dart';
import '../../utils/theme.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploadingProfile = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController.text = user?.name ?? '';
    Future.microtask(() => ref.read(storageProvider.notifier).fetchUsage());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateProfileImage() async {
    setState(() => _isUploadingProfile = true);
    try {
      final url = await UploadService().pickAndUploadImage();
      if (url != null) {
        // Update backend (Supabase profiles table)
        final email = ref.read(userProvider)?.email ?? '';
        await AuthService().updateUserMetadata({'profile_image': url, 'email': email});
        // Update local provider + SharedPreferences
        await ref.read(userProvider.notifier).updateProfileImage(url);
        if (mounted) {
          NotificationHelper.success(context, 'Profile picture updated!', title: 'Updated');
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  void _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final email = ref.read(userProvider)?.email ?? '';
    // Update backend (Supabase profiles table)
    await AuthService().updateUserMetadata({'name': name, 'email': email});
    // Update local provider + SharedPreferences
    await ref.read(userProvider.notifier).updateName(name);
    if (mounted) {
      NotificationHelper.success(context, 'Display name updated!', title: 'Saved');
      setState(() => _isEditingName = false);
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'You will need to log in again to access your notes.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    // Capture navigator before any async operations
    final navigator = Navigator.of(context);

    // Clear Supabase session + clear local user data
    await AuthService().logout();
    await ref.read(userProvider.notifier).clearUser();

    // Navigate immediately to AuthScreen, clearing entire back-stack
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the userProvider — UI auto-updates when name/photo changes
    final user = ref.watch(userProvider);
    final storageAsync = ref.watch(storageProvider);
    final name = user?.name.isNotEmpty == true ? user!.name : 'User';
    final email = user?.email ?? '';
    final profileImage = user?.profileImage;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.5, -0.8),
                  radius: 1.2,
                  colors: [Color(0xFF1E1B4B), Color(0xFF0B0F19)],
                ),
              ),
            ),
          ),
          // Top purple orb
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const HeroIcon(HeroIcons.arrowLeft, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'My Profile',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar + Name section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _isUploadingProfile ? null : _updateProfileImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  image: profileImage != null
                                      ? DecorationImage(image: NetworkImage(profileImage), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: _isUploadingProfile
                                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                    : (profileImage == null
                                        ? Center(
                                            child: Text(
                                              initials,
                                              style: GoogleFonts.outfit(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : null),
                              ),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                                child: const HeroIcon(HeroIcons.camera, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                        const SizedBox(height: 20),

                        // Name (editable)
                        if (_isEditingName)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Display name',
                                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                    border: InputBorder.none,
                                    enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.primary)),
                                    focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppColors.primary, width: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _saveName,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HeroIcon(HeroIcons.check, size: 18, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() => _isEditingName = false),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HeroIcon(HeroIcons.xMark, size: 18, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: () => setState(() => _isEditingName = true),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const HeroIcon(HeroIcons.pencilSquare, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),

                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 8),
                        // Verified badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Account',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Storage Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const HeroIcon(HeroIcons.archiveBox, size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Text('Storage Usage',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          storageAsync.when(
                            data: (info) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${(info.usedBytes / (1024 * 1024)).toStringAsFixed(2)} MB used',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      '${(info.totalBytes / (1024 * 1024)).toStringAsFixed(0)} MB total',
                                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: (info.percentage / 100).clamp(0.0, 1.0)),
                                    duration: const Duration(seconds: 2),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) => LinearProgressIndicator(
                                      value: value,
                                      minHeight: 12,
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        value > 0.8 ? Colors.red.shade400 : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${info.percentage.toStringAsFixed(1)}% of storage used',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: info.percentage > 80 ? Colors.red.shade400 : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) =>
                                Text('Error loading storage', style: TextStyle(color: Colors.red.shade400)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Account Info Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const HeroIcon(HeroIcons.userCircle, size: 20, color: Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Text('Account Details',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(icon: HeroIcons.envelope, label: 'Email', value: email),
                          const SizedBox(height: 12),
                          _InfoRow(icon: HeroIcons.user, label: 'Display Name', value: name),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: HeroIcons.shieldCheck,
                            label: 'Account Status',
                            value: 'Verified',
                            valueColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Quick Actions Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const HeroIcon(HeroIcons.bolt, size: 20, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Text('Quick Actions',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ActionTile(
                            icon: HeroIcons.photo,
                            label: 'Change Profile Photo',
                            subtitle: 'Update your avatar',
                            iconColor: Colors.purple,
                            onTap: _isUploadingProfile ? null : _updateProfileImage,
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _ActionTile(
                            icon: HeroIcons.pencil,
                            label: 'Edit Display Name',
                            subtitle: 'Change how others see you',
                            iconColor: Colors.blue,
                            onTap: () => setState(() => _isEditingName = true),
                          ),
                          const Divider(color: Colors.white10, height: 1),
                          _ActionTile(
                            icon: HeroIcons.lockClosed,
                            label: 'Change Password',
                            subtitle: 'Update your security credentials',
                            iconColor: Colors.green,
                            onTap: () {
                              NotificationHelper.show(
                                context,
                                title: 'Reset Password',
                                message: 'Use "Forgot Password" on the login screen to reset your password.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Logout button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: _isLoggingOut
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.12),
                                foregroundColor: Colors.red.shade400,
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: _logout,
                              icon: const HeroIcon(HeroIcons.arrowLeftOnRectangle, size: 20),
                              label: Text(
                                'Sign Out',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                  ).animate().fadeIn(delay: 700.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroIcon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: HeroIcon(icon, size: 18, color: iconColor),
      ),
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const HeroIcon(HeroIcons.chevronRight, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
