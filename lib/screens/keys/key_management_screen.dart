import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/key_model.dart';
import '../../providers/shortcut_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../services/upload_service.dart';
import '../../utils/notification_helper.dart';
import 'favorites_screen.dart';

class KeyManagementScreen extends ConsumerStatefulWidget {
  const KeyManagementScreen({super.key});

  @override
  ConsumerState<KeyManagementScreen> createState() => _KeyManagementScreenState();
}

class _KeyManagementScreenState extends ConsumerState<KeyManagementScreen> {
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shortcutProvider.notifier).fetchKeys());
  }

  void _navigateToCreateKey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateKeyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(shortcutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Managed Keys'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
            icon: const HeroIcon(HeroIcons.star, style: HeroIconStyle.solid, color: Colors.amber),
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: HeroIcon(_isGridView ? HeroIcons.listBullet : HeroIcons.squares2x2),
          ),
        ],
      ),
      body: keys.isEmpty
          ? const Center(child: Text('No keys created yet.'))
          : _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) => _KeyCard(keyItem: keys[index]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length,
                  itemBuilder: (context, index) => _KeyListTile(keyItem: keys[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateKey,
        child: const HeroIcon(HeroIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final KeyModel keyItem;
  const _KeyCard({required this.keyItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '/${keyItem.keyName}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              keyItem.title ?? 'No Title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              keyItem.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (keyItem.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(keyItem.imageUrl!, height: 80, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            if (keyItem.links != null && keyItem.links!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...keyItem.links!.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const HeroIcon(HeroIcons.link, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${link.title}: ${link.url}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer(builder: (context, ref, child) {
                  return IconButton(
                    onPressed: () => ref.read(shortcutProvider.notifier).toggleFavorite(keyItem.id),
                    icon: HeroIcon(
                      keyItem.isFavorite ? HeroIcons.star : HeroIcons.star,
                      style: keyItem.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                      color: keyItem.isFavorite ? Colors.amber : null,
                      size: 20,
                    ),
                  );
                }),
                IconButton(
                  onPressed: () => Share.share(
                    'Check out my Key: /${keyItem.keyName}\n${keyItem.title}\n${keyItem.description}',
                  ),
                  icon: const HeroIcon(HeroIcons.share, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyListTile extends StatelessWidget {
  final KeyModel keyItem;
  const _KeyListTile({required this.keyItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Consumer(builder: (context, ref, child) {
          return IconButton(
            onPressed: () => ref.read(shortcutProvider.notifier).toggleFavorite(keyItem.id),
            icon: HeroIcon(
              keyItem.isFavorite ? HeroIcons.star : HeroIcons.star,
              style: keyItem.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
              color: keyItem.isFavorite ? Colors.amber : null,
              size: 20,
            ),
          );
        }),
        title: Text('/${keyItem.keyName}', style: const TextStyle(color: AppColors.primary)),
        subtitle: Text(keyItem.title ?? 'No Title'),
        trailing: IconButton(
          onPressed: () => Share.share(
            'Check out my Key: /${keyItem.keyName}\n${keyItem.title}\n${keyItem.description}',
          ),
          icon: const HeroIcon(HeroIcons.share, size: 20),
        ),
      ),
    );
  }
}

class CreateKeyScreen extends StatelessWidget {
  const CreateKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Key'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const HeroIcon(HeroIcons.chevronLeft),
        ),
      ),
      body: const SingleChildScrollView(
        child: AddKeyForm(),
      ),
    );
  }
}

class AddKeyForm extends ConsumerStatefulWidget {
  const AddKeyForm({super.key});

  @override
  ConsumerState<AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<AddKeyForm> {
  final _keyNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, TextEditingController>> _linkControllers = [];
  String? _imageUrl;
  bool _isUploading = false;

  void _addLinkField() {
    setState(() {
      _linkControllers.add({
        'title': TextEditingController(),
        'url': TextEditingController(),
      });
    });
  }

  void _removeLinkField(int index) {
    setState(() {
      _linkControllers[index]['title']!.dispose();
      _linkControllers[index]['url']!.dispose();
      _linkControllers.removeAt(index);
    });
  }

  void _pickImage() async {
    setState(() => _isUploading = true);
    try {
      final url = await UploadService().pickAndUploadImage();
      if (url != null) {
        setState(() => _imageUrl = url);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _keyNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controllers in _linkControllers) {
      controllers['title']?.dispose();
      controllers['url']?.dispose();
    }
    super.dispose();
  }

  void _save() async {
    final user = ref.read(userProvider);
    if (user == null) {
      NotificationHelper.error(context, 'User not logged in.');
      return;
    }

    final keyName = _keyNameController.text.trim();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (keyName.isEmpty) {
      NotificationHelper.error(context, 'Key Name is required.');
      return;
    }

    final newKey = KeyModel(
      id: '',
      userId: user.id,
      keyName: keyName,
      title: title.isEmpty ? null : title,
      description: description.isEmpty ? null : description,
      links: _linkControllers.map((c) => KeyLink(
        title: c['title']!.text.trim(),
        url: c['url']!.text.trim(),
      )).where((l) => l.url.isNotEmpty).toList(),
      imageUrl: _imageUrl,
      createdAt: DateTime.now(),
    );

    await ref.read(shortcutProvider.notifier).addKey(newKey);
    await ref.read(shortcutProvider.notifier).fetchKeys();
    
    if (mounted) {
      NotificationHelper.success(context, 'Key "/$keyName" saved successfully!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _keyNameController, decoration: const InputDecoration(hintText: 'Key Name (e.g. project)')),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Title')),
          const SizedBox(height: 16),
          TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Description')),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Links', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(onPressed: _addLinkField, icon: const HeroIcon(HeroIcons.plusCircle, color: AppColors.primary)),
            ],
          ),
          ..._linkControllers.asMap().entries.map((entry) {
            int idx = entry.key;
            var controllers = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(controller: controllers['title'], decoration: const InputDecoration(hintText: 'Link Title')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(controller: controllers['url'], decoration: const InputDecoration(hintText: 'URL')),
                  ),
                  IconButton(
                    onPressed: () => _removeLinkField(idx),
                    icon: const HeroIcon(HeroIcons.trash, size: 20, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const HeroIcon(HeroIcons.photo, size: 20),
                  label: Text(_imageUrl != null ? 'Change Image' : 'Add Image'),
                ),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _save, child: const Text('Save Key')),
        ],
      ),
    );
  }
}
