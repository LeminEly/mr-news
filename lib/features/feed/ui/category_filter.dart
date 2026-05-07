import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/feed_providers.dart';
import '../../../shared/models/models.dart';

class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final locale = ref.watch(appLocaleProvider);

    return categoriesAsync.when(
      data: (categories) => Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CategoryChip(
                label: locale.languageCode == 'ar' ? 'الكل' : 'Tout',
                isSelected: selectedCategoryId == null,
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
              );
            }

            final category = categories[index - 1];
            final isSelected = selectedCategoryId == category.id;

            return _CategoryChip(
              label: category.name(locale),
              icon: category.icon,
              colorHex: category.colorHex,
              isSelected: isSelected,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = category.id,
            );
          },
        ),
      ),
      loading: () => const _LoadingShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? icon;
  final String? colorHex;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.icon,
    this.colorHex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? accentColor = colorHex != null 
        ? Color(int.parse(colorHex!.replaceAll('#', '0xFF'))) 
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        avatar: icon != null ? Text(icon!) : null,
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: accentColor?.withOpacity(0.2) ?? AppColors.primarySurface,
        checkmarkColor: accentColor ?? AppColors.primary,
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: isSelected 
              ? (accentColor ?? AppColors.primary) 
              : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected 
                ? (accentColor ?? AppColors.primary) 
                : AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(4, (index) => Container(
          width: 80,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.chipRadius,
          ),
        )),
      ),
    );
  }
}
