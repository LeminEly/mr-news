import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/features/agency/providers/agency_locale_provider.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Sélecteur FR / AR pour l'espace agence uniquement.
class AgencyLanguageSwitcher extends ConsumerWidget {
  const AgencyLanguageSwitcher({
    super.key,
    this.compact = false,
    this.iconColor,
  });

  final bool compact;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(agencyLocaleProvider).languageCode;
    final l10n = context.agencyL10n;
    final fg = iconColor ?? Theme.of(context).appBarTheme.foregroundColor;

    if (compact) {
      return PopupMenuButton<String>(
        tooltip: l10n.t('language'),
        icon: Icon(Icons.language, color: fg),
        onSelected: (v) =>
            ref.read(agencyLocaleProvider.notifier).setLocale(v),
        itemBuilder: (_) => [
          CheckedPopupMenuItem(
            value: 'fr',
            checked: code == 'fr',
            child: const Text('Français'),
          ),
          CheckedPopupMenuItem(
            value: 'ar',
            checked: code == 'ar',
            child: const Text('العربية'),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        segments: const [
          ButtonSegment(value: 'fr', label: Text('FR')),
          ButtonSegment(value: 'ar', label: Text('AR')),
        ],
        selected: {code},
        onSelectionChanged: (selection) {
          if (selection.isEmpty) return;
          ref.read(agencyLocaleProvider.notifier).setLocale(selection.first);
        },
      ),
    );
  }
}
