import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';
import '../data/categories_repository.dart';
import 'admin_drawer.dart';

class CategoriesCrudScreen extends ConsumerWidget {
  const CategoriesCrudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Gestion des Catégories',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showCategoryDialog(context, ref),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(allCategoriesProvider.future),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(child: Text('Aucune catégorie trouvée'));
            }

            return ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCrudTile(category: category);
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

  static void showCategoryDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? category]) {
    final isEditing = category != null;
    final nameFrController = TextEditingController(text: category?['name_fr'] ?? '');
    final nameArController = TextEditingController(text: category?['name_ar'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '📁');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameFrController,
                decoration: const InputDecoration(labelText: 'Nom (FR)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameArController,
                decoration: const InputDecoration(labelText: 'Nom (AR)'),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Emoji Icon'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name_fr': nameFrController.text.trim(),
                'name_ar': nameArController.text.trim(),
                'icon': iconController.text.trim(),
              };

              try {
                if (isEditing) {
                  await ref.read(categoriesRepositoryProvider).updateCategory(
                    categoryId: category['id'],
                    nameFr: data['name_fr'],
                    nameAr: data['name_ar'],
                    icon: data['icon'],
                  );
                } else {
                  await ref.read(categoriesRepositoryProvider).createCategory(
                    nameFr: data['name_fr']!,
                    nameAr: data['name_ar']!,
                    icon: data['icon']!,
                    colorHex: '#000000', // Default color
                  );
                }
                ref.invalidate(allCategoriesProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Enregistrer' : 'Créer'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCrudTile extends ConsumerWidget {
  const _CategoryCrudTile({required this.category});

  final Map<String, dynamic> category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Text(category['icon'] ?? '📁', style: const TextStyle(fontSize: 24)),
        title: Text(category['name_fr'] ?? 'Sans nom', style: AppTextStyles.labelLarge),
        subtitle: Text(category['name_ar'] ?? '', style: const TextStyle(fontFamily: 'Roboto')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => CategoriesCrudScreen.showCategoryDialog(context, ref, category),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('Voulez-vous vraiment supprimer "${category['name_fr']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(categoriesRepositoryProvider).deleteCategory(category['id']);
                ref.invalidate(allCategoriesProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
