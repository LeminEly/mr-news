import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../feed/providers/feed_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../main.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final isAr = locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            children: [
              const Spacer(),
              // Logo Placeholder / Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppShadows.card,
                ),
                child: const Icon(
                  Icons.newspaper_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const Gap(AppSpacing.xxxl),
              
              Text(
                isAr ? 'مرحباً بك في موريتانيا نيوز' : 'Bienvenue sur Mauritanie News',
                style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const Gap(AppSpacing.lg),
              Text(
                isAr 
                  ? 'اخبار موريتانيا لحظة بلحظة، بكل موضوعية ومهنية.' 
                  : 'L\'actualité mauritanienne en temps réel, avec objectivité et professionnalisme.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Language Selection
              Text(
                isAr ? 'اختر لغتك المفضلة' : 'Choisissez votre langue',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
              const Gap(AppSpacing.lg),
              
              Row(
                children: [
                  Expanded(
                    child: _LanguageCard(
                      label: 'العربية',
                      isSelected: isAr,
                      onTap: () => _setLocale('ar'),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: _LanguageCard(
                      label: 'Français',
                      isSelected: !isAr,
                      onTap: () => _setLocale('fr'),
                    ),
                  ),
                ],
              ),
              
              const Gap(AppSpacing.xxxl),
              
              ElevatedButton(
                onPressed: _completeOnboarding,
                child: Text(isAr ? 'ابدأ الآن' : 'Commencer maintenant'),
              ),
              const Gap(AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _setLocale(String lang) {
    ref.read(appLocaleProvider.notifier).state = Locale(lang);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    await prefs.setString(AppConstants.keyAppLanguage, ref.read(appLocaleProvider).languageCode);
    
    if (mounted) {
      context.go(AppRoutes.feed);
    }
  }
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          boxShadow: isSelected ? AppShadows.card : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.headlineMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
