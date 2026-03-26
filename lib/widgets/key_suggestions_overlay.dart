import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/key_model.dart';
import '../../providers/shortcut_provider.dart';
import '../../utils/theme.dart';

class KeySuggestionsOverlay extends ConsumerWidget {
  final String query;
  final Function(KeyModel) onSelected;

  const KeySuggestionsOverlay({
    super.key,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter keys based on query (strip leading '/' if present)
    final searchTerm = query.startsWith('/') ? query.substring(1) : query;
    final keys = ref.watch(shortcutProvider.notifier).searchKeys(searchTerm);

    if (keys.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: keys.length,
          separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder, height: 1),
          itemBuilder: (context, index) {
            final key = keys[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const HeroIcon(HeroIcons.key, size: 18, color: AppColors.primary),
              ),
              title: Text(
                '/${key.keyName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                key.title ?? 'No title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onTap: () => onSelected(key),
            );
          },
        ),
      ),
    );
  }
}
