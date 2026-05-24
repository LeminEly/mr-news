import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/features/agency/providers/agency_locale_provider.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Enveloppe un écran de l'espace agence (locale FR/AR, RTL, police).
class AgencyLocaleScope extends ConsumerWidget {
  const AgencyLocaleScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(agencyLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    final fontFamily = isAr ? AppTextStyles.fontAr : AppTextStyles.fontFr;

    return Localizations(
      locale: locale,
      delegates: const [
        AgencyLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Theme(
              data: theme.copyWith(
                textTheme: theme.textTheme.apply(fontFamily: fontFamily),
                primaryTextTheme:
                    theme.primaryTextTheme.apply(fontFamily: fontFamily),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper pour les routes `/agency/*` dans le routeur.
Widget agencyRoute(Widget child) => AgencyLocaleScope(child: child);

/// Navigation interne (dashboard → publish / edit / profil).
Route<T> agencyMaterialRoute<T>(Widget screen) {
  return MaterialPageRoute<T>(
    builder: (_) => AgencyLocaleScope(child: screen),
  );
}
