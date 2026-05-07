import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../providers/feed_providers.dart';
import '../../../main.dart';

class DateBanner extends ConsumerWidget {
  const DateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final locale = ref.watch(appLocaleProvider);
    
    // Generate last 14 days
    final dates = List.generate(14, (index) {
      return DateTime.now().subtract(Duration(days: index));
    });

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          
          return _DateItem(
            date: date,
            isSelected: isSelected,
            isToday: isToday,
            locale: locale,
            onTap: () => ref.read(selectedDateProvider.notifier).state = date,
          );
        },
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final Locale locale;
  final VoidCallback onTap;

  const _DateItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = locale.languageCode;
    
    String label;
    if (isToday) {
      label = lang == 'ar' ? 'اليوم' : 'Aujourd\'hui';
    } else {
      label = DateFormat.MMMd(lang).format(date);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.chipRadius,
          boxShadow: isSelected ? AppShadows.card : null,
          border: isSelected ? null : Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
