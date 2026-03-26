import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/style_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../providers/lock_provider.dart';
import '../../providers/storage_provider.dart';
import '../../utils/theme.dart';
import '../../utils/notification_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final chatStyle = ref.watch(styleProvider);
    final lockState = ref.watch(lockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Appearance',
            items: [
              _SettingsItem(
                icon: themeMode == ThemeMode.dark ? HeroIcons.moon : HeroIcons.sun,
                label: 'Dark Mode',
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ),
              _SettingsItem(
                icon: HeroIcons.squares2x2,
                label: 'Chat Style',
                trailing: DropdownButton<ChatStyle>(
                  value: chatStyle,
                  underline: const SizedBox(),
                  onChanged: (s) {
                    if (s != null) ref.read(styleProvider.notifier).setStyle(s);
                  },
                  items: ChatStyle.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Backup & Security',
            items: [
              _SettingsItem(
                icon: HeroIcons.cloudArrowUp,
                label: 'Cloud Sync',
                trailing: const Text('Enabled', style: TextStyle(color: AppColors.accent)),
              ),
              _SettingsItem(
                icon: lockState.isEnabled ? HeroIcons.lockClosed : HeroIcons.lockOpen,
                label: 'Lock Notes',
                trailing: Text(lockState.isEnabled ? 'Active' : 'Disabled', style: TextStyle(color: lockState.isEnabled ? AppColors.accent : Colors.grey)),
                onTap: () => _showLockDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Supabase Storage',
            items: [
              _SettingsItem(
                icon: HeroIcons.cloud,
                label: 'Initialize Personal Bucket',
                trailing: const HeroIcon(HeroIcons.chevronRight),
                onTap: () => _showBucketSetupDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Export',
            items: [
              _SettingsItem(
                icon: HeroIcons.documentText,
                label: 'Export as PDF',
                onTap: () {
                  final notes = ref.read(notesProvider);
                  ExportService.exportNotesAsPdf(notes);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLockDialog(BuildContext context, WidgetRef ref) {
    final lockState = ref.read(lockProvider);
    if (!lockState.isEnabled) {
      _showSetupLockDialog(context, ref);
    } else {
      _showDisableLockDialog(context, ref);
    }
  }

  void _showSetupLockDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup App Lock'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                ref.read(lockProvider.notifier).setLock(true, pinController.text);
                Navigator.pop(context);
                NotificationHelper.success(context, 'App Lock Enabled');
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showDisableLockDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable App Lock'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter current PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final currentPin = ref.read(lockProvider).pin;
              if (pinController.text == currentPin) {
                ref.read(lockProvider.notifier).setLock(false, null);
                Navigator.pop(context);
                NotificationHelper.success(context, 'App Lock Disabled');
              } else {
                NotificationHelper.error(context, 'Incorrect PIN');
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showBucketSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _BucketSetupDialog(),
    );
  }
}

class _BucketSetupDialog extends ConsumerStatefulWidget {
  const _BucketSetupDialog();

  @override
  ConsumerState<_BucketSetupDialog> createState() => _BucketSetupDialogState();
}

class _BucketSetupDialogState extends ConsumerState<_BucketSetupDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = AuthService().currentUser?.email ?? '';
  }

  void _setup() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      await AuthService().ensureBucket(email);
      ref.read(storageProvider.notifier).fetchUsage();
      
      if (mounted) {
        NotificationHelper.success(context, 'Storage Bucket initialized successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Initialize Storage'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your credentials to enable your private storage bucket.', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          TextField(controller: _emailController, decoration: const InputDecoration(hintText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: 'Password (Required for verification)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _setup,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Initialize'),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Card(child: Column(children: items)),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HeroIcon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
