import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
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
        _loadError = a == null ? context.agencyL10n.t('profile_not_found') : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  String _mediaTypeLabel(MediaType t, AgencyLocalizations l10n) {
    switch (t) {
      case MediaType.newsAgency:
        return l10n.t('media_news_agency');
      case MediaType.newspaper:
        return l10n.t('media_newspaper');
      case MediaType.blog:
        return l10n.t('media_blog');
      case MediaType.tvChannel:
        return l10n.t('media_tv');
      case MediaType.radio:
        return l10n.t('media_radio');
      case MediaType.other:
        return l10n.t('media_other');
    }
  }

  String _statusLabel(AgencyStatus? s, AgencyLocalizations l10n) {
    switch (s) {
      case AgencyStatus.accepted:
        return l10n.t('status_approved');
      case AgencyStatus.pending:
        return l10n.t('status_pending');
      case AgencyStatus.rejected:
        return l10n.t('status_rejected');
      case AgencyStatus.suspended:
        return l10n.t('status_suspended');
      case null:
        return '—';
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
            context.agencyL10n.t('logo_web_unavailable'),
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
            context.agencyL10n.t('logo_updated'),
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
            '${context.agencyL10n.t('logo_upload_failed')} : $e',
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
    final l10n = context.agencyL10n;
    final dateLocale = l10n.isAr ? 'ar_SA' : 'fr_FR';
    final datePattern = l10n.isAr ? "d MMM yyyy، HH:mm" : "d MMM yyyy 'à' HH:mm";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.t('profile_title'),
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
                                            color: AppColors.primary.withOpacity(0.85),
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
                                              color: AppColors.primary.withOpacity(0.85),
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
                              l10n.t('change_logo_hint'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            l10n.t('profile_info'),
                            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _infoRow(l10n.t('field_name'), _agency!.name),
                          _infoRow(l10n.t('field_email'), _agency!.email),
                          _infoRow(
                            l10n.t('website_label'),
                            (_agency!.websiteUrl ?? '—').trim().isEmpty
                                ? '—'
                                : _agency!.websiteUrl!.trim(),
                          ),
                          _infoRow(l10n.t('media_type'), _mediaTypeLabel(_agency!.mediaType, l10n)),
                          _infoRow(l10n.t('field_status'), _statusLabel(_agency!.status, l10n)),
                          if ((_agency!.rejectReason ?? '').trim().isNotEmpty)
                            _infoRow(l10n.t('reject_reason'), _agency!.rejectReason!.trim()),
                          _infoRow(
                            l10n.t('account_created'),
                            DateFormat(datePattern, dateLocale)
                                .format(_agency!.createdAt.toLocal()),
                          ),
                          if (_agency!.validatedAt != null)
                            _infoRow(
                              l10n.t('validated_at'),
                              DateFormat(datePattern, dateLocale)
                                  .format(_agency!.validatedAt!.toLocal()),
                            ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
    );
  }
}
