import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/shortcut_provider.dart';
import '../../utils/theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allKeys = ref.watch(shortcutProvider);
    final favoriteKeys = allKeys.where((k) => k.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Keys'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const HeroIcon(HeroIcons.chevronLeft),
        ),
      ),
      body: favoriteKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(HeroIcons.star, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No favorite keys yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteKeys.length,
              itemBuilder: (context, index) {
                final keyItem = favoriteKeys[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: IconButton(
                      onPressed: () => ref.read(shortcutProvider.notifier).toggleFavorite(keyItem.id),
                      icon: const HeroIcon(
                        HeroIcons.star,
                        style: HeroIconStyle.solid,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                    title: Text('/${keyItem.keyName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    subtitle: Text(keyItem.title ?? 'No Title'),
                    trailing: IconButton(
                      onPressed: () => Share.share(
                        'Check out my Favorite Key: /${keyItem.keyName}\n${keyItem.title}\n${keyItem.description}',
                      ),
                      icon: const HeroIcon(HeroIcons.share, size: 20),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
