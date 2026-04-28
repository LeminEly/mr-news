import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/agency_model.dart';
import 'admin_drawer.dart';
import 'agencies_list.dart';

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
                final filtered = agencies.where((AgencyModel a) {
                  return a.name.toLowerCase().contains(_searchQuery) ||
                      a.email.toLowerCase().contains(_searchQuery);
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
                    final agency = filtered[index];
                    final dateStr = DateFormat('d MMM yyyy', 'fr_FR').format(agency.createdAt);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            agency.name.substring(0, 1).toUpperCase(),
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                agency.name,
                                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _RoleChip(role: agency.mediaType.name),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            Text(agency.email, style: AppTextStyles.bodySmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Created: $dateStr', style: AppTextStyles.meta),
                          ],
                        ),
                        onTap: () {
                          // TODO: Détails de l'utilisateur ou édition du rôle
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, __) => Center(child: Text('Error: $err')),
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
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
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
