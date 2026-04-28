import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/feed/providers/feed_providers.dart';

import '../features/feed/ui/feed_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/agency/ui/agency_register_screen.dart';
import '../features/agency/ui/agency_login_screen.dart';
import '../features/agency/ui/agency_pending.dart';
import '../features/agency/ui/publish_article_screen.dart';
import '../features/agency/ui/agency_profile.dart';
import '../shared/models/agency_model.dart';
import '../features/admin/ui/stats_dashboard.dart';
import '../features/admin/ui/agency_validation.dart';
import '../features/admin/ui/reports_management.dart';
import '../features/admin/ui/categories_management.dart';
import '../features/admin/ui/agencies_list.dart';
import '../features/admin/ui/users_management.dart';
import '../features/admin/ui/admin_login_screen.dart';
import '../features/agency/ui/agency_dashboard_screen.dart';
import '../features/webview/ui/article_webview_screen.dart';
import '../features/auth/ui/unified_auth_screen.dart';
import '../features/auth/ui/auth_home_screen.dart';

class AppRoutes {
  static const String splash          = '/splash';
  static const String authHome        = '/';
  static const String onboarding      = '/onboarding';
  static const String feed            = '/feed';
  static const String articleWebView  = '/article';
  static const String agencyRegister  = '/agency/register';
  static const String agencyLogin     = '/agency/login';
  static const String agencyPending   = '/agency/pending';
  static const String agencyDashboard = '/agency/dashboard';
  static const String agencyPublish   = '/agency/publish';
  static const String agencyEditArticle = '/agency/edit';
  static const String agencyProfile   = '/agency/profile';
  static const String adminDashboard  = '/admin';
  static const String adminValidation = '/admin/validation';
  static const String adminReports    = '/admin/reports';
  static const String adminCategories = '/admin/categories';
  static const String adminAgencies   = '/admin/agencies';
  static const String adminUsers      = '/admin/users';
  static const String adminLogin      = '/admin/login';
}

// Global flag to allow test admin login without Supabase backend dependency
bool bypassAdminAuth = false;

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.authHome,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final role = user?.userMetadata?['role'] as String?;
      final isAuthenticated = user != null;
      final loc = state.matchedLocation;

      // Splash & AuthHome -> laisse passer
      if (loc == AppRoutes.splash || loc == AppRoutes.authHome) return null;

      // Routes publiques 
      final publicRoutes = [
        AppRoutes.onboarding,
        AppRoutes.feed,
        AppRoutes.articleWebView,
        AppRoutes.agencyRegister,
        AppRoutes.agencyLogin,
        AppRoutes.adminLogin,
      ];
      if (publicRoutes.any((r) => loc.startsWith(r))) return null;

      // Bypass test for Admin
      if (bypassAdminAuth && loc.startsWith('/admin')) return null;

      // Protection globale : si non auth -> AuthHome
      if (!isAuthenticated) return AppRoutes.authHome;

      // Routes agence — doit etre auth + role agency
      if (loc.startsWith('/agency')) {
        if (role != 'agency' && role != 'admin') return AppRoutes.feed;
        // Le check du statut "pending" est fait dans la "Gate" du dashboard
        return null;
      }

      // Routes admin — doit etre auth + role admin
      if (loc.startsWith('/admin')) {
        if (role != 'admin') return AppRoutes.feed;
        return null;
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
          return ArticleWebViewScreen(url: extra['url']!, title: extra['title']!);
        },
      ),

      // Agence : Inscription
      GoRoute(
        path: AppRoutes.agencyRegister,
        name: 'agency-register',
        builder: (context, state) => const AgencyRegisterScreen(),
      ),

      // Agence : Login
      GoRoute(
        path: AppRoutes.agencyLogin,
        name: 'agency-login',
        builder: (context, state) => const AgencyLoginScreen(),
      ),

      // Agence : Attente validation
      GoRoute(
        path: AppRoutes.agencyPending,
        name: 'agency-pending',
        builder: (context, state) => const AgencyPendingScreen(),
      ),

      // Agence : Dashboard
      GoRoute(
        path: AppRoutes.agencyDashboard,
        name: 'agency-dashboard',
        builder: (context, state) => const AgencyDashboardGate(),
      ),

      // Agence : Publier
      GoRoute(
        path: AppRoutes.agencyPublish,
        name: 'agency-publish',
        builder: (context, state) => const AgencyPublishGate(),
      ),

      // Agence : Modifier article
      GoRoute(
        path: AppRoutes.agencyEditArticle,
        name: 'agency-edit-article',
        builder: (context, state) => const Scaffold(),
      ),

      // Agence : Profil
      GoRoute(
        path: AppRoutes.agencyProfile,
        name: 'agency-profile',
        builder: (context, state) {
          final extra = state.extra;
          return AgencyProfileScreen(
            agency: extra is AgencyModel ? extra : null,
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

      // Admin : Catégories
      GoRoute(
        path: AppRoutes.adminCategories,
        name: 'admin-categories',
        builder: (context, state) => const CategoriesManagementScreen(),
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

      // Admin : Login
      GoRoute(
        path: AppRoutes.adminLogin,
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.error}'),
      ),
    ),
  );
});

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.authHome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class AgencyDashboardGate extends ConsumerWidget {
  const AgencyDashboardGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyAsync = ref.watch(currentAgencyProvider);

    return agencyAsync.when(
      data: (agency) {
        if (agency.status == AgencyStatus.pending) {
          return const AgencyPendingScreen();
        }
        return AgencyDashboardScreen(agency: agency);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('Erreur: $err'),
        ),
      ),
    );
  }
}