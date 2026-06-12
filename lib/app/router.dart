import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/feed/ui/feed_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/agency/ui/agency_register_screen.dart';
import '../features/agency/ui/agency_login_screen.dart';
import '../features/agency/ui/agency_pending.dart';
import '../features/agency/ui/publish_article_screen.dart';
import '../features/agency/ui/agency_profile.dart';
import '../features/agency/ui/agency_dashboard_gate.dart';
import '../features/agency/ui/agency_locale_scope.dart';
import '../shared/models/agency_model.dart';
import '../features/admin/ui/stats_dashboard.dart';
import '../features/admin/ui/agency_validation.dart';
import '../features/admin/ui/reports_management.dart';
import '../features/admin/ui/category_analytics_screen.dart';
import '../features/admin/ui/categories_crud_screen.dart';
import '../features/admin/ui/agencies_list.dart';
import '../features/admin/ui/users_management.dart';
import '../features/admin/ui/admin_login_screen.dart';
import '../features/admin/ui/agency_details_screen.dart';
import '../features/admin/ui/articles_management.dart';
import '../features/webview/ui/article_webview_screen.dart';
import '../features/auth/ui/unified_auth_screen.dart';
import '../features/auth/ui/auth_home_screen.dart';
import '../features/auth/ui/reset_password_screen.dart';
import '../features/feed/ui/splash_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String authHome = '/';
  static const String onboarding = '/onboarding';
  static const String feed = '/feed';
  static const String articleWebView = '/article';
  static const String agencyRegister = '/agency/register';
  static const String agencyLogin = '/agency/login';
  static const String agencyPending = '/agency/pending';
  static const String agencyDashboard = '/agency/dashboard';
  static const String agencyPublish = '/agency/publish';
  static const String agencyEditArticle = '/agency/edit';
  static const String agencyProfile = '/agency/profile';
  static const String adminDashboard = '/admin';
  static const String adminValidation = '/admin/validation';
  static const String adminReports = '/admin/reports';
  static const String adminCategories = '/admin/categories';
  static const String adminCategoryAnalytics = '/admin/category-analytics';
  static const String adminAgencies = '/admin/agencies';
  static const String adminUsers = '/admin/users';
  static const String adminArticles = '/admin/articles';
  static const String adminLogin = '/admin/login';
  static const String adminAgencyDetails = '/admin/agency-details';
  static const String resetPassword = '/auth/reset-password';
}

// Global flag to allow test admin login without Supabase backend dependency
bool bypassAdminAuth = false;

/// Réévalue le redirect sans recréer GoRouter (évite reset vers / → /feed après login).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.authHome,
    refreshListenable: authRefresh,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Guard for administration area
      if (location.startsWith('/admin')) {
        if (location == AppRoutes.adminLogin) {
          return null;
        }
        if (!bypassAdminAuth) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null || user.userMetadata?['role'] != 'admin') {
            return AppRoutes.adminLogin;
          }
        }
        return null;
      }

      // Guard for agency portal
      if (location.startsWith('/agency')) {
        if (location == AppRoutes.agencyLogin ||
            location == AppRoutes.agencyRegister) {
          return null;
        }
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return AppRoutes.agencyLogin;
        }
        return null;
      }

      // Ces routes ne doivent JAMAIS être redirigées par ce guard global.
      if (location == AppRoutes.feed ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.articleWebView ||
          location == AppRoutes.splash ||
          location == AppRoutes.resetPassword ||
          location == '/auth-unified') {
        return null;
      }

      // Route racine / → fil d'actualité
      if (location == '/' || location == AppRoutes.authHome) {
        return AppRoutes.feed;
      }

      return null;
    },
    routes: [
      // Auth Home
      GoRoute(
        path: AppRoutes.authHome,
        name: 'auth-home',
        builder: (context, state) => const AuthHomeScreen(),
      ),

      // Unified Auth (Keep for now if needed by other components)
      GoRoute(
        path: '/auth-unified',
        name: 'auth-unified',
        builder: (context, state) => const UnifiedAuthScreen(),
      ),

      // Reset password (OTP flow — admin & agency)
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(initialEmail: state.extra as String?),
      ),

      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Feed (lecteur)
      GoRoute(
        path: AppRoutes.feed,
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),

      // Article WebView
      GoRoute(
        path: AppRoutes.articleWebView,
        name: 'article',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return ArticleWebViewScreen(
              url: extra['url']!, title: extra['title']!);
        },
      ),

      // Agence : Inscription
      GoRoute(
        path: AppRoutes.agencyRegister,
        name: 'agency-register',
        builder: (context, state) => agencyRoute(const AgencyRegisterScreen()),
      ),

      // Agence : Login
      GoRoute(
        path: AppRoutes.agencyLogin,
        name: 'agency-login',
        builder: (context, state) => agencyRoute(const AgencyLoginScreen()),
      ),

      // Agence : Attente validation
      GoRoute(
        path: AppRoutes.agencyPending,
        name: 'agency-pending',
        builder: (context, state) => agencyRoute(const AgencyPendingScreen()),
      ),

      GoRoute(
        path: AppRoutes.agencyDashboard,
        name: 'agency-dashboard',
        builder: (context, state) {
          final extra = state.extra;
          return agencyRoute(
            AgencyDashboardGate(
              initialAgency: extra is AgencyModel ? extra : null,
            ),
          );
        },
      ),

      // Agence : Publier
      GoRoute(
        path: AppRoutes.agencyPublish,
        name: 'agency-publish',
        builder: (context, state) => agencyRoute(const AgencyPublishGate()),
      ),

      // Agence : Modifier article
      GoRoute(
        path: AppRoutes.agencyEditArticle,
        name: 'agency-edit-article',
        builder: (context, state) => agencyRoute(const Scaffold()),
      ),

      // Agence : Profil
      GoRoute(
        path: AppRoutes.agencyProfile,
        name: 'agency-profile',
        builder: (context, state) {
          final extra = state.extra;
          return agencyRoute(
            AgencyProfileScreen(
              agency: extra is AgencyModel ? extra : null,
            ),
          );
        },
      ),

      // Admin : Dashboard
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Admin : Validation agences
      GoRoute(
        path: AppRoutes.adminValidation,
        name: 'admin-validation',
        builder: (context, state) => const AgencyValidationScreen(),
      ),

      // Admin : Signalements
      GoRoute(
        path: AppRoutes.adminReports,
        name: 'admin-reports',
        builder: (context, state) => const ReportsManagementScreen(),
      ),

      // Admin : Catégories (CRUD)
      GoRoute(
        path: AppRoutes.adminCategories,
        name: 'admin-categories',
        builder: (context, state) => const CategoriesCrudScreen(),
      ),
      
      // Admin : Analytiques des catégories
      GoRoute(
        path: AppRoutes.adminCategoryAnalytics,
        name: 'admin-category-analytics',
        builder: (context, state) => const CategoryAnalyticsScreen(),
      ),

      // Admin : Agences
      GoRoute(
        path: AppRoutes.adminAgencies,
        name: 'admin-agencies',
        builder: (context, state) => const AgenciesListScreen(),
      ),

      // Admin : Users
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const UsersManagementScreen(),
      ),

      // Admin : Articles
      GoRoute(
        path: AppRoutes.adminArticles,
        name: 'admin-articles',
        builder: (context, state) => const ArticlesManagementScreen(),
      ),

      // Admin : Login
      GoRoute(
        path: AppRoutes.adminLogin,
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Admin : Détails Agence
      GoRoute(
        path: AppRoutes.adminAgencyDetails,
        name: 'admin-agency-details',
        builder: (context, state) {
          final agency = state.extra as AgencyModel;
          return AgencyDetailsScreen(agency: agency);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.error}'),
      ),
    ),
  );
});
