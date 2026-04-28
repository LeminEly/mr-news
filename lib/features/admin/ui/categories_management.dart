import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

class CategoriesManagementScreen extends ConsumerWidget {
  const CategoriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Catégories',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bientôt: Ajouter une catégorie')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(categoriesProvider.future),
        child: categoriesAsync.when(
          data: (categories) {
            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.cardRadius,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                    title: Text(category.nameFr, style: AppTextStyles.labelLarge),
                    subtitle: Text(category.nameAr, style: AppTextStyles.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Erreur: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}
