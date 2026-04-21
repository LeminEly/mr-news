import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/feed/providers/feed_providers.dart';

// Route names
class AppRoutes {
  static const String splash          = '/';
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
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final role = user?.userMetadata?['role'] as String?;
      final isAuthenticated = user != null;
      final loc = state.matchedLocation;

      // Splash -> laisse passer
      if (loc == AppRoutes.splash) return null;

      // Routes publiques 
      final publicRoutes = [
        AppRoutes.onboarding,
        AppRoutes.feed,
        AppRoutes.articleWebView,
        AppRoutes.agencyRegister,
        AppRoutes.agencyLogin,
      ];
      if (publicRoutes.any((r) => loc.startsWith(r))) return null;

      // Routes agence — doit etre auth + role agency
      if (loc.startsWith('/agency')) {
        if (!isAuthenticated) return AppRoutes.agencyLogin;
        if (role != 'agency' && role != 'admin') return AppRoutes.feed;
        return null;
      }

      // Routes admin — doit etre auth + role admin
      if (loc.startsWith('/admin')) {
        if (!isAuthenticated) return AppRoutes.agencyLogin;
        if (role != 'admin') return AppRoutes.feed;
        return null;
      }

      return null;
    },
    routes: [
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
            url:   extra['url']!,
            title: extra['title']!,
            articleId: extra['articleId']!,
          );
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
        builder: (context, state) => const AgencyDashboardScreen(),
      ),

      // Agence : Publier
      GoRoute(
        path: AppRoutes.agencyPublish,
        name: 'agency-publish',
        builder: (context, state) => const PublishArticleScreen(),
      ),

      // Agence : Modifier article
      GoRoute(
        path: AppRoutes.agencyEditArticle,
        name: 'agency-edit-article',
        builder: (context, state) {
          final articleId = state.extra as String;
          return EditArticleScreen(articleId: articleId);
        },
      ),

      // Agence : Profil
      GoRoute(
        path: AppRoutes.agencyProfile,
        name: 'agency-profile',
        builder: (context, state) => const AgencyProfileScreen(),
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
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page non trouvée: ${state.error}'),
      ),
    ),
  );
});

// Ces imports seront résolus une fois les screens créés

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class ArticleWebViewScreen extends StatelessWidget {
  final String url, title, articleId;
  const ArticleWebViewScreen({super.key, required this.url, required this.title, required this.articleId});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyRegisterScreen extends StatelessWidget {
  const AgencyRegisterScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyLoginScreen extends StatelessWidget {
  const AgencyLoginScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyPendingScreen extends StatelessWidget {
  const AgencyPendingScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyDashboardScreen extends StatelessWidget {
  const AgencyDashboardScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class PublishArticleScreen extends StatelessWidget {
  const PublishArticleScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class EditArticleScreen extends StatelessWidget {
  final String articleId;
  const EditArticleScreen({super.key, required this.articleId});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyProfileScreen extends StatelessWidget {
  const AgencyProfileScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgencyValidationScreen extends StatelessWidget {
  const AgencyValidationScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class ReportsManagementScreen extends StatelessWidget {
  const ReportsManagementScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class CategoriesManagementScreen extends StatelessWidget {
  const CategoriesManagementScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}

class AgenciesListScreen extends StatelessWidget {
  const AgenciesListScreen({super.key});
  @override Widget build(BuildContext context) => const Scaffold();
}