import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../main.dart';

class EmojiPanel extends ConsumerWidget {
  final String articleId;

  const EmojiPanel({
    super.key,
    required this.articleId,
  });

  static void show(BuildContext context, String articleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiPanel(articleId: articleId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReactionAsync = ref.watch(myReactionProvider(articleId));
    final locale = ref.watch(appLocaleProvider);
    final isAr = locale.languageCode == 'ar';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bottomSheet,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(AppSpacing.xl),
          
          Text(
            isAr ? 'كيف كانت قراءتك؟' : 'Comment était votre lecture ?',
            style: AppTextStyles.headlineMedium,
          ),
          const Gap(AppSpacing.xxl),

          myReactionAsync.when(
            data: (myReaction) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: EmojiType.values.map((emoji) {
                final isSelected = myReaction == emoji;
                return _EmojiItem(
                  emoji: emoji,
                  isSelected: isSelected,
                  onTap: () => _handleReaction(ref, context, emoji, isSelected),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
          const Gap(AppSpacing.huge),
        ],
      ),
    );
  }

  void _handleReaction(WidgetRef ref, BuildContext context, EmojiType emoji, bool isSelected) async {
    final repo = ref.read(reactionRepositoryProvider);
    
    try {
      if (isSelected) {
        await repo.removeReaction(articleId);
      } else {
        await repo.react(articleId: articleId, emoji: emoji);
      }
      
      // Refresh providers
      ref.invalidate(myReactionProvider(articleId));
      ref.invalidate(feedArticlesProvider);
      
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

class _EmojiItem extends StatelessWidget {
  final EmojiType emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiItem({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color emojiColor;
    switch (emoji) {
      case EmojiType.like:  emojiColor = AppColors.emojiLike; break;
      case EmojiType.wow:   emojiColor = AppColors.emojiWow; break;
      case EmojiType.sad:   emojiColor = AppColors.emojiSad; break;
      case EmojiType.angry: emojiColor = AppColors.emojiAngry; break;
      case EmojiType.fire:  emojiColor = AppColors.emojiFire; break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? emojiColor.withOpacity(0.1) : AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? emojiColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: emojiColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: Text(
              _getEmojiChar(emoji),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            _getEmojiLabel(emoji),
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? emojiColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiChar(EmojiType type) {
    switch (type) {
      case EmojiType.like: return '👍';
      case EmojiType.wow: return '😮';
      case EmojiType.sad: return '😢';
      case EmojiType.angry: return '😡';
      case EmojiType.fire: return '🔥';
    }
  }

  String _getEmojiLabel(EmojiType type) {
    switch (type) {
      case EmojiType.like: return 'J\'aime';
      case EmojiType.wow: return 'Waouh';
      case EmojiType.sad: return 'Triste';
      case EmojiType.angry: return 'Grrr';
      case EmojiType.fire: return 'Feu';
    }
  }
}
