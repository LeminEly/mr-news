import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profil agence : informations + changement de logo.
class AgencyProfileScreen extends ConsumerStatefulWidget {
  const AgencyProfileScreen({super.key, this.agency});

  /// Si null (ex. route `/agency/profile`), le profil est chargé via la session.
  final AgencyModel? agency;

  @override
  ConsumerState<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends ConsumerState<AgencyProfileScreen> {
  AgencyModel? _agency;
  bool _loading = true;
  String? _loadError;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_resolveAgency);
  }

  Future<void> _resolveAgency() async {
    if (widget.agency != null) {
      if (!mounted) return;
      setState(() {
        _agency = widget.agency;
        _loading = false;
      });
      return;
    }
    try {
      final a =
          await AgencyAuthService(Supabase.instance.client).getCurrentAgency();
      if (!mounted) return;
      setState(() {
        _agency = a;
        _loading = false;
        _loadError = a == null ? 'Profil agence introuvable' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  String _mediaTypeLabel(MediaType t) {
    switch (t) {
      case MediaType.newsAgency:
        return 'Agence de presse';
      case MediaType.newspaper:
        return 'Presse écrite';
      case MediaType.blog:
        return 'Blog';
      case MediaType.tvChannel:
        return 'Télévision';
      case MediaType.radio:
        return 'Radio';
      case MediaType.other:
        return 'Autre';
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final agency = _agency;
    if (agency == null) return;
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Le changement de logo depuis la galerie n’est pas disponible sur le web.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _uploadingLogo = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final updated = await ref.read(agencyRepositoryProvider).updateAgencyProfile(
            agencyId: agency.id,
            logoBytes: bytes,
            logoFileExt: ext,
          );
      if (!mounted) return;
      setState(() {
        _agency = updated;
        _uploadingLogo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Logo mis à jour',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Échec du téléversement : $e',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            value,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Mon profil',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : _agency == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: AppSpacing.pagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: ClipOval(
                                    child: (_agency!.logoUrl ?? '').trim().isEmpty
                                        ? Icon(
                                            Icons.business_rounded,
                                            size: 56,
                                            color: AppColors.primary.withValues(alpha: 0.85),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: _agency!.logoUrl!.trim(),
                                            width: 112,
                                            height: 112,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Shimmer.fromColors(
                                              baseColor: AppColors.surfaceVariant,
                                              highlightColor: AppColors.surface,
                                              child: Container(
                                                width: 112,
                                                height: 112,
                                                color: AppColors.surfaceVariant,
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) => Icon(
                                              Icons.business_rounded,
                                              size: 56,
                                              color: AppColors.primary.withValues(alpha: 0.85),
                                            ),
                                          ),
                                  ),
                                ),
                                if (!kIsWeb)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Material(
                                      color: AppColors.primary,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _uploadingLogo ? null : _pickAndUploadLogo,
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.sm),
                                          child: _uploadingLogo
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.textOnPrimary,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: AppColors.textOnPrimary,
                                                  size: 22,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Appuyez sur l’icône appareil photo pour changer le logo.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            'Informations',
                            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _infoRow('Nom', _agency!.name),
                          _infoRow('E-mail', _agency!.email),
                          _infoRow(
                            'Site web',
                            (_agency!.websiteUrl ?? '—').trim().isEmpty
                                ? '—'
                                : _agency!.websiteUrl!.trim(),
                          ),
                          _infoRow('Type de média', _mediaTypeLabel(_agency!.mediaType)),
                          _infoRow('Statut', _agency!.status.label),
                          if ((_agency!.rejectReason ?? '').trim().isNotEmpty)
                            _infoRow('Motif (rejet)', _agency!.rejectReason!.trim()),
                          _infoRow(
                            'Compte créé le',
                            DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR')
                                .format(_agency!.createdAt.toLocal()),
                          ),
                          if (_agency!.validatedAt != null)
                            _infoRow(
                              'Validé le',
                              DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR')
                                  .format(_agency!.validatedAt!.toLocal()),
                            ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
    );
  }
}
