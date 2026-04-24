import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';

/// Élément de menu mis en surbrillance dans le drawer.
enum AgencyDrawerSelection {
  dashboard,
  publish,
}

/// Menu latéral agence avec en-tête en dégradé et statut.
class AgencyDrawer extends StatelessWidget {
  const AgencyDrawer({
    super.key,
    required this.onClose,
    required this.onDashboard,
    required this.onPublish,
    required this.onProfile,
    required this.onLogout,
    this.agency,
    this.selectedItem = AgencyDrawerSelection.dashboard,
  });

  final VoidCallback onClose;
  final VoidCallback onDashboard;
  final VoidCallback onPublish;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final AgencyDrawerSelection selectedItem;
  final AgencyModel? agency;

  @override
  Widget build(BuildContext context) {
    final a = agency;
    final logoUrl = (a?.logoUrl ?? '').trim();
    final name = (a?.name ?? 'Agence').trim();
    final status = a?.status;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeaderFade(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surface,
                        child: ClipOval(
                          child: logoUrl.isEmpty
                              ? const Icon(
                                  Icons.business_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                )
                              : CachedNetworkImage(
                                  imageUrl: logoUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Shimmer.fromColors(
                                    baseColor: AppColors.surfaceVariant,
                                    highlightColor: AppColors.surface,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      color: AppColors.surfaceVariant,
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.business_rounded,
                                    color: AppColors.primary,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textOnPrimary,
                        fontFamily: AppTextStyles.fontFr,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerTile(
                    icon: '🏠',
                    label: 'Dashboard',
                    selected: selectedItem == AgencyDrawerSelection.dashboard,
                    onTap: () {
                      onDashboard();
                      onClose();
                    },
                  ),
                  _DrawerTile(
                    icon: '📝',
                    label: 'Publier un article',
                    selected: selectedItem == AgencyDrawerSelection.publish,
                    onTap: () {
                      onPublish();
                      onClose();
                    },
                  ),
                  _DrawerTile(
                    icon: '👤',
                    label: 'Mon Profil',
                    selected: false,
                    onTap: () {
                      onProfile();
                      onClose();
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _DrawerTile(
                    icon: '🚪',
                    label: 'Déconnexion',
                    selected: false,
                    danger: true,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeaderFade extends StatefulWidget {
  const _DrawerHeaderFade({required this.child});

  final Widget child;

  @override
  State<_DrawerHeaderFade> createState() => _DrawerHeaderFadeState();
}

class _DrawerHeaderFadeState extends State<_DrawerHeaderFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
      child: widget.child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AgencyStatus? status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final label = () {
      switch (s) {
        case AgencyStatus.approved:
          return '✅ Approuvée';
        case AgencyStatus.pending:
          return '⏳ En attente';
        case AgencyStatus.rejected:
          return '❌ Rejetée';
        case AgencyStatus.suspended:
          return '⛔ Suspendue';
        case null:
          return '—';
      }
    }();

    final (bg, fg, border) = () {
      switch (s) {
        case AgencyStatus.approved:
          return (AppColors.successLight, AppColors.success, AppColors.success);
        case AgencyStatus.pending:
          return (AppColors.warningLight, AppColors.warning, AppColors.warning);
        case AgencyStatus.rejected:
          return (AppColors.errorLight, AppColors.error, AppColors.error);
        case AgencyStatus.suspended:
          return (AppColors.errorLight, AppColors.error, AppColors.error);
        case null:
          return (AppColors.surfaceVariant, AppColors.textSecondary, AppColors.border);
      }
    }();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: AppSpacing.chipPadding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primarySurface : Colors.transparent;
    final textColor = danger ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(icon, style: AppTextStyles.headlineSmall),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
