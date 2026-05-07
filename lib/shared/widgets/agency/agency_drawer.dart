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
                    icon: Icons.dashboard_rounded,
                    label: 'Tableau de bord',
                    selected: selectedItem == AgencyDrawerSelection.dashboard,
                    onTap: () {
                      onDashboard();
                      onClose();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Publier un article',
                    selected: selectedItem == AgencyDrawerSelection.publish,
                    onTap: () {
                      onPublish();
                      onClose();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Mon Profil',
                    selected: false,
                    onTap: () {
                      onProfile();
                      onClose();
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
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
        case AgencyStatus.approved: return 'Approuvée';
        case AgencyStatus.pending: return 'En attente';
        case AgencyStatus.rejected: return 'Rejetée';
        case AgencyStatus.suspended: return 'Suspendue';
        case null: return '—';
      }
    }();

    final icon = () {
      switch (s) {
        case AgencyStatus.approved: return Icons.check_circle_rounded;
        case AgencyStatus.pending: return Icons.access_time_rounded;
        case AgencyStatus.rejected: return Icons.cancel_rounded;
        case AgencyStatus.suspended: return Icons.block_rounded;
        case null: return Icons.help_outline_rounded;
      }
    }();

    final (bg, fg, border) = () {
      switch (s) {
        case AgencyStatus.approved:
          return (AppColors.success.withOpacity(0.1), AppColors.success, AppColors.success);
        case AgencyStatus.pending:
          return (AppColors.warning.withOpacity(0.1), AppColors.warning, AppColors.warning);
        case AgencyStatus.rejected:
          return (AppColors.error.withOpacity(0.1), AppColors.error, AppColors.error);
        case AgencyStatus.suspended:
          return (AppColors.error.withOpacity(0.1), AppColors.error, AppColors.error);
        case null:
          return (AppColors.surfaceVariant, AppColors.textSecondary, AppColors.border);
      }
    }();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: border.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(color: fg, fontWeight: FontWeight.bold),
            ),
          ],
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

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary.withOpacity(0.08) : Colors.transparent;
    final textColor = danger ? AppColors.error : AppColors.textPrimary;
    final iconColor = selected ? AppColors.primary : (danger ? AppColors.error : AppColors.textSecondary);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
