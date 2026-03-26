import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/note_model.dart';
import '../../models/conversation_model.dart';
import '../../models/key_model.dart';
import '../../providers/notes_provider.dart';
import '../../providers/shortcut_provider.dart';
import '../../services/upload_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_sidebar.dart';
import 'image_preview_screen.dart';
import '../keys/key_management_screen.dart';
import '../../providers/style_provider.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/key_suggestions_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _uploadService = UploadService();
  String _searchQuery = "";
  bool _isSearching = false;
  String _suggestionQuery = "";
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(conversationProvider.notifier).fetchConversations();
      final activeId = ref.read(conversationProvider).activeConversationId;
      ref.read(notesProvider.notifier).fetchNotes(activeId);
      ref.read(shortcutProvider.notifier).fetchKeys();
    });
    _messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    final text = _messageController.text;
    if (text.startsWith('/') || text.toLowerCase() == 'j') {
      setState(() {
        _showSuggestions = true;
        _suggestionQuery = text;
      });
    } else if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
        _suggestionQuery = "";
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProvider);
    if (user == null) return;
    
    // Check for shortcut expansion
    final expandedKey = ref.read(shortcutProvider.notifier).expandKey(text);
    
    if (expandedKey != null) {
      _expandKeyIntoNote(expandedKey);
    } else {
      // Regular text note
      final note = NoteModel(
        id: '',
        userId: user.id,
        description: text,
        createdAt: DateTime.now(),
      );
      final activeId = ref.read(conversationProvider).activeConversationId;
      await ref.read(notesProvider.notifier).addNote(note, activeId);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _expandKeyIntoNote(KeyModel key) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final note = NoteModel(
      id: '',
      userId: user.id,
      title: 'Shortcut: /${key.keyName}',
      description: key.description ?? (key.title != null ? 'Title: ${key.title}' : null),
      imageUrl: key.imageUrl,
      links: key.links,
      createdAt: DateTime.now(),
    );
    
    final activeId = ref.read(conversationProvider).activeConversationId;
    await ref.read(notesProvider.notifier).addNote(note, activeId);
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendImage() async {
    final imageUrl = await _uploadService.pickAndUploadImage();
    if (imageUrl == null) return;

    final user = ref.read(userProvider);
    if (user == null) return;

    final note = NoteModel(
      id: '',
      userId: user.id,
      description: 'Shared an image',
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    
    final activeId = ref.read(conversationProvider).activeConversationId;
    await ref.read(notesProvider.notifier).addNote(note, activeId);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(conversationProvider.select((s) => s.activeConversationId), (previous, next) {
      if (previous != next) {
        ref.read(notesProvider.notifier).fetchNotes(next);
      }
    });

    final allNotes = ref.watch(notesProvider);
    final sortedNotes = [...allNotes];
    sortedNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    final notes = sortedNotes.where((n) {
      final query = _searchQuery.toLowerCase();
      return (n.title?.toLowerCase().contains(query) ?? false) ||
             (n.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    final activeConv = ref.watch(conversationProvider).conversations.firstWhere(
      (c) => c.id == ref.watch(conversationProvider).activeConversationId,
      orElse: () => ConversationModel(id: '', userId: '', createdAt: DateTime.now(), title: 'New Chat'),
    );

    return Scaffold(
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white60),
                ),
              )
            : Text(activeConv.title ?? 'KeyNote'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = "";
            }),
            icon: HeroIcon(_isSearching ? HeroIcons.xMark : HeroIcons.magnifyingGlass),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat?'),
                  content: const Text('This will delete all messages in this conversation.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final activeId = ref.read(conversationProvider).activeConversationId;
                ref.read(notesProvider.notifier).clearLocalNotes();
                await ref.read(conversationProvider.notifier).clearActiveChat();
                ref.read(notesProvider.notifier).fetchNotes(activeId);
              }
            },
            icon: const HeroIcon(HeroIcons.trash, color: Colors.red),
          ),
          Builder(builder: (context) {
            return IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const HeroIcon(HeroIcons.bars3BottomRight),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _ChatBubble(note: note)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutCubic);
              },
            ),
          ),
          if (_showSuggestions)
            KeySuggestionsOverlay(
              query: _suggestionQuery,
              onSelected: (key) {
                setState(() => _showSuggestions = false);
                _expandKeyIntoNote(key);
              },
            ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onImagePick: _sendImage,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final NoteModel note;
  const _ChatBubble({required this.note});

  @override
  Widget build(BuildContext context) {
    final hasExtra = note.title != null || note.imageUrl != null || (note.links != null && note.links!.isNotEmpty);

    return Consumer(builder: (context, ref, child) {
      final style = ref.watch(styleProvider);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      Color bubbleColor;
      Border? bubbleBorder;
      BorderRadius bubbleRadius;

      final isShortcut = note.title?.startsWith('Shortcut: /') ?? false;

      switch (style) {
        case ChatStyle.bubble:
          bubbleColor = hasExtra ? AppColors.primary : AppColors.primary.withValues(alpha: 0.9);
          bubbleBorder = Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1);
          bubbleRadius = BorderRadius.circular(24);
          break;
        case ChatStyle.minimal:
          bubbleColor = Colors.transparent;
          bubbleBorder = Border.all(
            color: isShortcut ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
            width: isShortcut ? 2 : 1,
          );
          bubbleRadius = BorderRadius.circular(12);
          break;
        case ChatStyle.glass:
          bubbleColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3);
          bubbleBorder = Border.all(
            color: (note.isPinned || isShortcut) ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
            width: (note.isPinned || isShortcut) ? 2 : 1,
          );
          bubbleRadius = BorderRadius.only(
            topLeft: const Radius.circular(24),
            bottomLeft: const Radius.circular(24),
            topRight: (note.isPinned || isShortcut) ? const Radius.circular(24) : const Radius.circular(4),
            bottomRight: const Radius.circular(24),
          );
      }

      Widget bubbleContainer = Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: bubbleRadius,
          border: bubbleBorder,
          boxShadow: style == ChatStyle.bubble ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isShortcut) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(HeroIcons.bolt, size: 12, color: AppColors.primary, style: HeroIconStyle.solid),
                    SizedBox(width: 4),
                    Text('KEY SHORTCUT', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (note.isPinned) ...[
              const Row(
                children: [
                  HeroIcon(HeroIcons.bookmark, size: 12, color: AppColors.primary, style: HeroIconStyle.solid),
                  SizedBox(width: 4),
                  Text('PINNED NOTE', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (note.title != null) ...[
              Text(
                note.title!,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: (style == ChatStyle.bubble) ? Colors.white : (isShortcut ? AppColors.primary : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              note.description ?? '',
              style: TextStyle(
                color: (style == ChatStyle.bubble) ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (note.imageUrl != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ImagePreviewScreen(imageUrl: note.imageUrl!, heroTag: note.id))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: note.imageUrl!,
                    child: Image.network(note.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 200),
                  ),
                ),
              ),
            ],
            if (note.links != null && note.links!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.links!.map((link) => _LinkChip(link: link)).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(note.createdAt),
                  style: TextStyle(
                    fontSize: 11, 
                    color: (style == ChatStyle.bubble) ? Colors.white.withValues(alpha: 0.6) : AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const HeroIcon(HeroIcons.trash, size: 16),
                      onPressed: () => ref.read(notesProvider.notifier).deleteNote(note.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: (style == ChatStyle.bubble) ? Colors.white.withValues(alpha: 0.6) : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: HeroIcon(note.isPinned ? HeroIcons.bookmark : HeroIcons.bookmark, 
                        style: note.isPinned ? HeroIconStyle.solid : HeroIconStyle.outline,
                        size: 16,
                      ),
                      onPressed: () => ref.read(notesProvider.notifier).togglePin(note),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: note.isPinned ? AppColors.primary : ((style == ChatStyle.bubble) ? Colors.white.withValues(alpha: 0.6) : AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      final wrappedContainer = GestureDetector(
        onTap: () => _showNoteActions(context, ref),
        child: bubbleContainer,
      );

      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: style == ChatStyle.glass 
            ? ClipRRect(
                borderRadius: bubbleRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: wrappedContainer,
                ),
              )
            : wrappedContainer,
        ),
      );
    });
  }

  void _showNoteActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: HeroIcon(note.isPinned ? HeroIcons.bookmark : HeroIcons.bookmark, 
                    style: note.isPinned ? HeroIconStyle.solid : HeroIconStyle.outline),
                title: Text(note.isPinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  ref.read(notesProvider.notifier).togglePin(note);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const HeroIcon(HeroIcons.pencilSquare),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref);
                },
              ),
              ListTile(
                leading: const HeroIcon(HeroIcons.trash, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(notesProvider.notifier).deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: note.title);
    final descController = TextEditingController(text: note.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(notesProvider.notifier).updateNote(
                      note.id,
                      titleController.text.trim(),
                      descController.text.trim(),
                    );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _LinkChip extends StatelessWidget {
  final KeyLink link;
  const _LinkChip({required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HeroIcon(HeroIcons.link, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              link.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImagePick;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add note or use /key...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateKeyScreen()),
            ),
            icon: const HeroIcon(HeroIcons.plusCircle, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          _AnimatedSendButton(onPressed: onSend),
        ],
      ),
    );
  }
}

class _AnimatedSendButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedSendButton({required this.onPressed});

  @override
  State<_AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<_AnimatedSendButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const HeroIcon(HeroIcons.paperAirplane, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
