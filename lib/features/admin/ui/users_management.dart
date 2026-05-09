import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import 'admin_drawer.dart';
import '../../feed/providers/feed_providers.dart';

/// Écran de gestion des utilisateurs et des rôles (Admin).
class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agenciesAsync = ref.watch(allAgenciesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Users & Roles',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search users or emails...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.buttonRadius,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: agenciesAsync.when(
              data: (agencies) {
                // Créer une liste d'objets "User" pour l'affichage
                final List<Map<String, dynamic>> allUsers = [];
                
                // Ajouter l'admin par défaut (hardcoded car pas de table users)
                allUsers.add({
                  'name': 'Abdellahi Admin',
                  'email': 'Abdellahi@g.com',
                  'role': 'ADMIN',
                  'created_at': DateTime(2024, 1, 1),
                  'id': 'admin-1',
                });

                // Ajouter les agences
                for (final agency in agencies) {
                  allUsers.add({
                    'name': agency.name,
                    'email': agency.email,
                    'role': 'AGENCY',
                    'created_at': agency.createdAt,
                    'id': agency.id,
                  });
                }

                final filtered = allUsers.where((u) {
                  final name = u['name'].toString().toLowerCase();
                  final email = u['email'].toString().toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No users found',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.pagePadding,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final createdAt = user['created_at'] as DateTime;
                    String dateStr;
                    try {
                      dateStr = DateFormat('d MMM yyyy').format(createdAt);
                    } catch (e) {
                      dateStr = createdAt.toString().split(' ')[0];
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: CircleAvatar(
                          backgroundColor: (user['role'] == 'ADMIN' ? AppColors.textPrimary : AppColors.primary).withOpacity(0.1),
                          child: Text(
                            user['name'].toString().substring(0, 1).toUpperCase(),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: user['role'] == 'ADMIN' ? AppColors.textPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['name'],
                                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _RoleChip(role: user['role']),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            Text(user['email'], style: AppTextStyles.bodySmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Created: $dateStr', style: AppTextStyles.meta),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Text(
        role.toUpperCase(),
        style: AppTextStyles.meta.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
