import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/notes_provider.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/keys/key_management_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/keys/favorites_screen.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convState = ref.watch(conversationProvider);
    final user = ref.watch(userProvider);
    final name = user?.name ?? 'Guest';
    final profileImage = user?.profileImage;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildSidebarHeader(context, ref, name, profileImage),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('CONVERSATIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                if (convState.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  ..._groupConversations(convState.conversations, convState.activeConversationId, ref, context),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                
                _SidebarItem(
                  icon: HeroIcons.key,
                  label: 'Managed Keys',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KeyManagementScreen()));
                  },
                ),
                _SidebarItem(
                  icon: HeroIcons.star,
                  label: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _SidebarItem(
            icon: HeroIcons.cog6Tooth,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          _SidebarItem(
            icon: HeroIcons.arrowLeftOnRectangle,
            label: 'Logout',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.card,
                  title: const Text('Logout?', style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                if (!context.mounted) return;
                final navigator = Navigator.of(context);
                navigator.pop(); // close drawer
                await AuthService().logout();
                await ref.read(userProvider.notifier).clearUser();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, WidgetRef ref, String name, String? profileImage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: const Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    ),
                    image: profileImage != null ? DecorationImage(image: NetworkImage(profileImage), fit: BoxFit.cover) : null,
                  ),
                  child: profileImage == null ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      },
                      child: Text(
                        'View Profile',
                        style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _groupConversations(List<dynamic> conversations, String? activeId, WidgetRef ref, BuildContext context) {
    if (conversations.isEmpty) return [];

    final now = DateTime.now();
    final today = conversations.where((c) => isSameDay(c.createdAt, now)).toList();
    final yesterday = conversations.where((c) => isSameDay(c.createdAt, now.subtract(const Duration(days: 1)))).toList();
    final previous = conversations.where((c) => !isSameDay(c.createdAt, now) && !isSameDay(c.createdAt, now.subtract(const Duration(days: 1)))).toList();

    List<Widget> items = [];
    if (today.isNotEmpty) {
      items.add(const _SectionHeader('Today'));
      items.addAll(today.map((c) => _buildItem(c, activeId, ref, context)));
    }
    if (yesterday.isNotEmpty) {
      items.add(const _SectionHeader('Yesterday'));
      items.addAll(yesterday.map((c) => _buildItem(c, activeId, ref, context)));
    }
    if (previous.isNotEmpty) {
      items.add(const _SectionHeader('Previous'));
      items.addAll(previous.map((c) => _buildItem(c, activeId, ref, context)));
    }
    return items;
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildItem(dynamic conv, String? activeId, WidgetRef ref, BuildContext context) {
    return _SidebarItem(
      icon: HeroIcons.chatBubbleLeft,
      label: conv.title ?? 'Untitled Chat',
      isSelected: conv.id == activeId,
      onTap: () {
        ref.read(conversationProvider.notifier).setActiveConversation(conv.id);
        ref.read(notesProvider.notifier).fetchNotes(conv.id);
        Navigator.pop(context);
      },
      onLongPress: () async {
        final controller = TextEditingController(text: conv.title);
        final newTitle = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Rename Conversation', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller, 
              autofocus: true, 
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Enter new title', hintStyle: TextStyle(color: Colors.white24)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
            ],
          ),
        );
        if (newTitle != null && newTitle.isNotEmpty) {
          await ref.read(conversationProvider.notifier).renameConversation(conv.id, newTitle);
        }
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Delete Conversation?', style: TextStyle(color: Colors.white)),
            content: const Text('This will delete all messages in this chat.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(conversationProvider.notifier).deleteConversation(conv.id);
          final activeId = ref.read(conversationProvider).activeConversationId;
          ref.read(notesProvider.notifier).fetchNotes(activeId);
        }
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final HeroIcons icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final VoidCallback? onDelete;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: HeroIcon(
        icon, 
        size: 20,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
      ),
      title: Text(
        label, 
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: onDelete != null && isSelected ? IconButton(
        icon: const HeroIcon(HeroIcons.trash, size: 16, color: Colors.white24),
        onPressed: onDelete,
      ) : null,
      onTap: onTap,
      onLongPress: onLongPress,
      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
