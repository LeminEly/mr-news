import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mauritanie_news/app/router.dart';
import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/features/agency/ui/agency_language_switch.dart';
import '../../../shared/theme/app_theme.dart';
import '../../feed/providers/feed_providers.dart';

class AgencyPendingScreen extends ConsumerWidget {
  const AgencyPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.agencyL10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          l10n.t('validation_title'),
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textOnPrimary),
        ),
        actions: const [
          AgencyLanguageSwitcher(compact: true),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 80, color: AppColors.warning),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.t('validation_title'),
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.t('validation_body'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(currentAgencyProvider);
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.t('check_again')),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  context.go(AppRoutes.agencyLogin);
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.t('sign_out')),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AgencyLanguageSwitcher(),
            ],
          ),
        ),
      ),
    );
  }
}
