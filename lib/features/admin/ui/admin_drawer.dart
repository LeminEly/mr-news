import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../app/router.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.textOnPrimary, size: 48),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Admin Panel',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.textOnPrimary),
                  ),
                ],
              ),
            ),
          ),
          _DrawerTile(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            isSelected: location == AppRoutes.adminDashboard,
            onTap: () => context.go(AppRoutes.adminDashboard),
          ),
          _DrawerTile(
            icon: Icons.business_outlined,
            label: 'Agencies',
            isSelected: location == AppRoutes.adminAgencies,
            onTap: () => context.go(AppRoutes.adminAgencies),
          ),
          _DrawerTile(
            icon: Icons.article_outlined,
            label: 'Articles',
            isSelected: location.startsWith('/admin/articles'), // Placeholder
            onTap: () {}, // Not implemented yet
          ),
          _DrawerTile(
            icon: Icons.warning_amber_rounded,
            label: 'Reports',
            isSelected: location == AppRoutes.adminReports,
            onTap: () => context.go(AppRoutes.adminReports),
          ),
          _DrawerTile(
            icon: Icons.category_outlined,
            label: 'Categories',
            isSelected: location == AppRoutes.adminCategories,
            onTap: () => context.go(AppRoutes.adminCategories),
          ),
          _DrawerTile(
            icon: Icons.people_outline,
            label: 'Users & Roles',
            isSelected: location == AppRoutes.adminUsers,
            onTap: () => context.go(AppRoutes.adminUsers),
          ),
          const Spacer(),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            textColor: AppColors.error,
            onTap: () async {
              bypassAdminAuth = false;
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go(AppRoutes.authHome);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isSelected
        ? AppColors.primary
        : (textColor ?? AppColors.textPrimary);

    return ListTile(
      leading: Icon(
        icon,
        color: effectiveColor,
      ),
      title: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: effectiveColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
