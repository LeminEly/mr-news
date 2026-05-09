import 'package:flutter/material.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:mauritanie_news/core/services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

class AgencyDetailsScreen extends StatelessWidget {
  final AgencyModel agency;

  const AgencyDetailsScreen({super.key, required this.agency});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: const Text('Détails de l\'Agence'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card with Logo
            Card(
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.cardRadius,
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.imageRadius,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadius.imageRadius,
                          child: agency.logoUrl != null && agency.logoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: agency.logoUrl!,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.business,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.business,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      agency.name,
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const Gap(AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(agency.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        agency.status.label.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _getStatusColor(agency.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.lg),

            // Informations générales
            _buildSection(
              title: 'Informations générales',
              children: [
                _buildInfoTile(Icons.business_outlined, 'Nom de l\'agence', agency.name),
                _buildInfoTile(Icons.category_outlined, 'Type de média', agency.mediaType.name),
                _buildInfoTile(Icons.calendar_today_outlined, 'Date d\'inscription', 
                  '${agency.createdAt.day}/${agency.createdAt.month}/${agency.createdAt.year}'),
              ],
            ),
            const Gap(AppSpacing.lg),

            // Contact
            _buildSection(
              title: 'Contact',
              children: [
                _buildInfoTile(Icons.email_outlined, 'Email officiel', agency.email),
                _buildInfoTile(Icons.language_outlined, 'Site web', agency.websiteUrl ?? 'Non renseigné'),
              ],
            ),
            const Gap(AppSpacing.lg),

            // Documents / Infos sup
            _buildSection(
              title: 'Documents',
              children: [
                if (agency.documentUrl != null && agency.documentUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    title: const Text('Document justificatif', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: const Text('Cliquer pour ouvrir le document', style: TextStyle(fontSize: 14)),
                    trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                    onTap: () => _launchUrl(agency.documentUrl!),
                  )
                else
                  _buildInfoTile(Icons.description_outlined, 'Document justificatif', 'Aucun document téléchargé'),
                
                if (agency.rejectReason != null && agency.rejectReason!.isNotEmpty)
                  _buildInfoTile(Icons.info_outline, 'Note / Raison du rejet', agency.rejectReason!),
              ],
            ),
            const Gap(AppSpacing.xxxl),

            // Download PDF Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => PdfService.generateAgencyDetailsPdf(agency),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Télécharger PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                ),
              ),
            ),
            const Gap(AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Card(
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      subtitle: Text(value, style: AppTextStyles.bodyMedium),
      dense: true,
    );
  }

  Color _getStatusColor(AgencyStatus status) {
    switch (status) {
      case AgencyStatus.accepted: return AppColors.success;
      case AgencyStatus.pending: return AppColors.warning;
      case AgencyStatus.rejected: return AppColors.error;
      case AgencyStatus.suspended: return AppColors.error;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}
