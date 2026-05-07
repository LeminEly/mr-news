import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../theme/app_theme.dart';
import '../../app/router.dart';
import '../../main.dart';

class ReaderDrawer extends ConsumerWidget {
  const ReaderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final isAr = locale.languageCode == 'ar';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 56, // Increased size slightly for better visibility
                    height: 56,
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    isAr ? 'موريتانيا نيوز' : 'Mauritanie News',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerSectionTitle(title: isAr ? 'الإعدادات' : 'Paramètres'),
                
                // Language
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primary),
                  title: Text(isAr ? 'تغيير اللغة' : 'Changer de langue'),
                  subtitle: Text(isAr ? 'العربية' : 'Français'),
                  onTap: () {
                    final newLocale = isAr ? const Locale('fr') : const Locale('ar');
                    ref.read(appLocaleProvider.notifier).state = newLocale;
                  },
                ),
                
                const Divider(),
                _DrawerSectionTitle(title: isAr ? 'منطقة الشركاء' : 'Espace Partenaires'),

                // Agency
                ListTile(
                  leading: const Icon(Icons.business_center_outlined, color: AppColors.secondary),
                  title: Text(isAr ? 'بوابة الوكالة' : 'Portail Agence'),
                  subtitle: Text(isAr ? 'نشر وإدارة مقالاتك' : 'Publier et gérer vos articles'),
                  onTap: () => context.push(AppRoutes.agencyLogin),
                ),

                // Admin
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.accent),
                  title: Text(isAr ? 'الإدارة' : 'Administration'),
                  subtitle: Text(isAr ? 'إدارة المنصة' : 'Gérer la plateforme'),
                  onTap: () => context.push(AppRoutes.adminDashboard),
                ),

                const Divider(),
                _DrawerSectionTitle(title: isAr ? 'معلومات' : 'Informations'),

                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textTertiary),
                  title: Text(isAr ? 'حول التطبيق' : 'À propos'),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'v1.0.0',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String title;
  const _DrawerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
