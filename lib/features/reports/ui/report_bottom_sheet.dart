import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../main.dart';

class ReportBottomSheet extends ConsumerStatefulWidget {
  final String articleId;

  const ReportBottomSheet({
    super.key,
    required this.articleId,
  });

  static void show(BuildContext context, String articleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportBottomSheet(articleId: articleId),
    );
  }

  @override
  ConsumerState<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends ConsumerState<ReportBottomSheet> {
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final isAr = locale.languageCode == 'ar';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bottomSheet,
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(AppSpacing.lg),

          Text(
            isAr ? 'إبلاغ عن محتوى' : 'Signaler un contenu',
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.sm),
          Text(
            isAr 
              ? 'ساعدنا في الحفاظ على جودة الأخبار من خلال الإبلاغ عن المحتوى غير المناسب.' 
              : 'Aidez-nous à maintenir la qualité des informations en signalant le contenu inapproprié.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.xl),

          ...ReportReason.values.map((reason) => _ReasonTile(
            label: isAr ? reason.labelAr : reason.labelFr,
            isSelected: _selectedReason == reason,
            onTap: () => setState(() => _selectedReason = reason),
          )),

          const Gap(AppSpacing.xl),

          ElevatedButton(
            onPressed: _selectedReason == null || _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isAr ? 'إرسال الإبلاغ' : 'Envoyer le signalement'),
          ),
          const Gap(AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    final repo = ref.read(reportRepositoryProvider);

    try {
      await repo.reportArticle(
        articleId: widget.articleId,
        reason: _selectedReason!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre signalement. Nous allons l\'examiner.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonRadius,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.error.withOpacity(0.05) : Colors.transparent,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }
}
