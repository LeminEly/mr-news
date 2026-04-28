import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

class AgencyPendingScreen extends StatelessWidget {
  const AgencyPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          'Validation en cours',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 80, color: AppColors.warning),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Validation en cours',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Votre demande d’inscription est en attente de validation par un administrateur. Vous recevrez un accès complet dès que votre compte sera approuvé.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: () {
                  Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

