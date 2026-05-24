import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mauritanie_news/app/router.dart';
import 'package:mauritanie_news/features/agency/data/agency_repository.dart';
import 'package:mauritanie_news/features/agency/localization/agency_l10n.dart';
import 'package:mauritanie_news/features/agency/ui/agency_dashboard_screen.dart';
import 'package:mauritanie_news/features/agency/ui/agency_pending.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Garde la route `/agency/dashboard` : session, statut agence, redirection login.
class AgencyDashboardGate extends ConsumerWidget {
  const AgencyDashboardGate({super.key, this.initialAgency});

  final AgencyModel? initialAgency;

  void _redirectToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(AppRoutes.agencyLogin);
      }
    });
  }

  bool _isUnauthenticatedError(Object error) {
    if (error is AgencyRepositoryException && error.code == 'UNAUTHENTICATED') {
      return true;
    }
    return error.toString().contains('UNAUTHENTICATED') ||
        error.toString().contains('Aucune session active');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.agencyL10n;
    final agencyAsync = ref.watch(currentAgencyProvider);

    return agencyAsync.when(
      data: (agency) {
        final resolved = initialAgency ?? agency;
        if (resolved == null) {
          _redirectToLogin(context);
          return const SizedBox.shrink();
        }

        if (resolved.status == AgencyStatus.pending) {
          return const AgencyPendingScreen();
        }

        if (resolved.status == AgencyStatus.rejected) {
          return const AgencyPendingScreen();
        }

        return AgencyDashboardScreen(agency: resolved);
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.t('loading_space')),
            ],
          ),
        ),
      ),
      error: (err, stack) {
        debugPrint('AgencyDashboardGate Error: $err\n$stack');
        if (_isUnauthenticatedError(err)) {
          _redirectToLogin(context);
          return const SizedBox.shrink();
        }
        return const AgencyPendingScreen();
      },
    );
  }
}
