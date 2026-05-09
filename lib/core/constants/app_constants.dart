class AppConstants {
  AppConstants._();

  // APP INFO 
  static const String appName = 'أخبار موريتانيا';
  static const String appNameFr = 'Actualités Mauritanie';
  static const String appVersion = '1.0.0';

  // SUPABASE TABLES
  static const String tableAgencies   = 'agencies';
  static const String tableArticles   = 'articles';
  static const String tableCategories = 'categories';
  static const String tableReactions  = 'reactions';
  static const String tableReports    = 'reports';

  // SUPABASE VIEWS
  static const String viewArticlesWithDetails    = 'articles_with_details';
  static const String viewArticleReactionCounts  = 'article_reaction_counts';
  static const String viewAdminArticlesOverview  = 'admin_articles_overview';

  // SUPABASE STORAGE BUCKETS
  static const String bucketArticleCovers = 'article-covers';
  static const String bucketAgencyLogos   = 'agency-logos';

  // SUPABASE REALTIME CHANNELS
  static const String channelArticles  = 'public:articles';
  static const String channelReactions = 'public:reactions';
  static const String channelReports   = 'public:reports';

  // PAGINATION
  static const int feedPageSize       = 20;
  static const int adminPageSize      = 30;

  // FEED
  static const int dateBannerDaysBack = 7;   // jours dans le bandeau de dates

  // STORAGE LIMITS
  static const int maxCoverImageSizeBytes = 5 * 1024 * 1024;  // 5MB
  static const int maxLogoSizeBytes       = 2 * 1024 * 1024;  // 2MB

  // USER ROLES
  static const String roleAdmin  = 'admin';
  static const String roleAgency = 'agency';

  // LOCAL STORAGE KEYS
  static const String keyDeviceId       = 'device_id';
  static const String keyAppLanguage    = 'app_language';
  static const String keyOnboardingDone = 'onboarding_done';

  // VALIDATION
  static const int minAgencyNameLength = 2;
  static const int minArticleTitleLength = 3;
  static const int minPasswordLength = 8;

  // REPORT THRESHOLD
  // Nombre de signalements pour marquer un article "sous surveillance"
  static const int reportAlertThreshold = 5;
}
