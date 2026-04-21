import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/feed_repository.dart';
import '../../agency/data/agency_repository.dart';
import '../../reactions/data/reaction_repository.dart';
import '../../reports/data/report_repository.dart';
import '../../admin/data/admin_repository.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/category_model.dart';

// SUPABASE CLIENT

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// AUTH STATE

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final currentUserRoleProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 'anonymous';
  return user.userMetadata?['role'] as String? ?? 'anonymous';
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserRoleProvider) == 'admin';
});

final isAgencyProvider = Provider<bool>((ref) {
  return ref.watch(currentUserRoleProvider) == 'agency';
});

// REPOSITORIES

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(supabaseClientProvider));
});

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return AgencyRepository(ref.watch(supabaseClientProvider));
});

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return ReactionRepository(ref.watch(supabaseClientProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(supabaseClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

// FEED STATE 

// Date sélectionnée dans le bandeau
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Catégorie filtre sélectionnée (null = toutes)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Articles du feed selon la date et catégorie sélectionnées
final feedArticlesProvider = FutureProvider.autoDispose<List<ArticleModel>>((ref) async {
  final date     = ref.watch(selectedDateProvider);
  final category = ref.watch(selectedCategoryProvider);
  final repo     = ref.watch(feedRepositoryProvider);

  if (category != null) {
    return repo.getArticlesByCategory(categoryId: category, date: date);
  }
  return repo.getArticlesByDate(date);
});

// Catégories (mise en cache)
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(feedRepositoryProvider).getCategories();
});

// Réaction de l'utilisateur sur un article spécifique
final myReactionProvider = FutureProvider.autoDispose
    .family<EmojiType?, String>((ref, articleId) async {
  return ref.watch(reactionRepositoryProvider).getMyReaction(articleId);
});

// Si l'utilisateur a déja signalé un article
final hasReportedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, articleId) async {
  return ref.watch(reportRepositoryProvider).hasReported(articleId);
});

// AGENCY STATE

final currentAgencyProvider = FutureProvider.autoDispose((ref) async {
  // Se recalcule quand l'auth change
  ref.watch(authStateProvider);
  return ref.watch(agencyRepositoryProvider).getCurrentAgency();
});

final myArticlesProvider = FutureProvider.autoDispose
    .family<List<ArticleModel>, String>((ref, agencyId) async {
  return ref.watch(agencyRepositoryProvider).getMyArticles(agencyId);
});

// ADMIN STATE

final adminStatsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(adminRepositoryProvider).getGlobalStats();
});

final pendingAgenciesProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(adminRepositoryProvider).getAgenciesByStatus(AgencyStatus.pending);
});

final pendingReportsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(adminRepositoryProvider).getPendingReports();
});