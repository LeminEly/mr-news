# 📱 Plateforme d'Actualités Mauritanienne
### Guide Développeur Frontend — Flutter

> **Stack:** Flutter · Supabase · Riverpod · GoRouter  
> **Projet:** Dev Mobile — SupNum  
> **Version:** 1.0.0

---

## 📦 Installation & Setup

### 1. Prérequis
```bash
Flutter SDK >= 3.16.0
Dart SDK >= 3.2.0
```

### 2. Cloner et installer
```bash
git clone <repo-url>
cd mauritanie_news
flutter pub get
```

### 3. Générer les fichiers auto (freezed, riverpod, json)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Variables d'environnement
Le fichier `.env` est déjà configuré à la racine du projet :
```
SUPABASE_URL=https://cbfuldmswluzwxfdipwy.supabase.co
SUPABASE_ANON_KEY=sb_publishable_qFSIwju3rpHdUN18lUHVgw_KdbmVP4h
```
> ⚠️ Ne jamais committer `.env` ni `lib/core/constants/env.g.dart`

### 5. Base de données Supabase
Exécuter le fichier SQL dans le dashboard Supabase :
```
supabase/migrations/001_initial_schema.sql
```
Aller sur → **Supabase Dashboard** → **SQL Editor** → Coller et exécuter.

### 6. Lancer l'app
```bash
flutter run
```

---

## 🎨 Design System — Couleurs

Toutes les couleurs sont dans `lib/shared/theme/app_theme.dart` → classe `AppColors`.

### Palette principale
| Constante | Hex | Usage |
|---|---|---|
| `AppColors.primary` | `#00C8A0` | CTA principal, boutons, liens actifs |
| `AppColors.primaryDark` | `#00A082` | Hover/pressed state du primary |
| `AppColors.primaryLight` | `#4DDFC4` | Icônes légères, indicateurs |
| `AppColors.primarySurface` | `#E6FAF6` | Background de chips/badges primary |
| `AppColors.secondary` | `#1A6B3C` | Vert drapeau mauritanien, accents |
| `AppColors.accent` | `#D4AF37` | Or drapeau mauritanien, highlights |

### Neutrals
| Constante | Hex | Usage |
|---|---|---|
| `AppColors.background` | `#F8FAFB` | Background de toutes les screens |
| `AppColors.surface` | `#FFFFFF` | Cards, modals, bottom sheets |
| `AppColors.surfaceVariant` | `#F1F5F9` | Inputs, zones secondaires |
| `AppColors.textPrimary` | `#1A2030` | Titres, textes principaux |
| `AppColors.textSecondary` | `#64748B` | Sous-titres, labels |
| `AppColors.textTertiary` | `#94A3B8` | Dates, metadata, placeholders |
| `AppColors.border` | `#E2E8F0` | Bordures de cards, séparateurs |
| `AppColors.divider` | `#F1F5F9` | ListTile dividers |

### Status colors
| Constante | Hex | Usage |
|---|---|---|
| `AppColors.success` | `#10B981` | Succès, agence approuvée |
| `AppColors.successLight` | `#D1FAE5` | Background badge succès |
| `AppColors.warning` | `#F59E0B` | Avertissement, en attente |
| `AppColors.warningLight` | `#FEF3C7` | Background badge warning |
| `AppColors.error` | `#EF4444` | Erreur, rejet, signalement |
| `AppColors.errorLight` | `#FEE2E2` | Background badge erreur |
| `AppColors.info` | `#3B82F6` | Info, liens |
| `AppColors.infoLight` | `#DBEAFE` | Background badge info |

### Statuts agence
| Constante | Hex | Usage |
|---|---|---|
| `AppColors.statusPending` | `#F59E0B` | Badge "En attente" |
| `AppColors.statusApproved` | `#10B981` | Badge "Approuvée" |
| `AppColors.statusRejected` | `#EF4444` | Badge "Rejetée" |
| `AppColors.statusSuspended`| `#6B7280` | Badge "Suspendue" |

### Couleurs des catégories
| Constante | Hex | Catégorie |
|---|---|---|
| `AppColors.catPolitique` | `#EF4444` | 🏛️ Politique |
| `AppColors.catEconomie` | `#F59E0B` | 📈 Économie |
| `AppColors.catSport` | `#10B981` | ⚽ Sport |
| `AppColors.catTechno` | `#3B82F6` | 💻 Technologie |
| `AppColors.catSociete` | `#8B5CF6` | 👥 Société |
| `AppColors.catSante` | `#EC4899` | 🏥 Santé |
| `AppColors.catCulture` | `#F97316` | 🎭 Culture |
| `AppColors.catInternational` | `#06B6D4` | 🌍 International |

### Couleurs des réactions emoji
| Constante | Hex | Emoji |
|---|---|---|
| `AppColors.emojiLike` | `#3B82F6` | 👍 J'aime |
| `AppColors.emojiWow` | `#F59E0B` | 😮 Surpris |
| `AppColors.emojiSad` | `#8B5CF6` | 😢 Triste |
| `AppColors.emojiAngry` | `#EF4444` | 😡 Fâché |
| `AppColors.emojiFire` | `#F97316` | 🔥 Chaud |

### Mode sombre
| Constante | Hex | Usage |
|---|---|---|
| `AppColors.darkBackground` | `#0A0C10` | Background dark |
| `AppColors.darkSurface` | `#0F1318` | Cards dark |
| `AppColors.darkSurface2` | `#151A22` | Surface secondaire dark |
| `AppColors.darkBorder` | `#1E2A38` | Bordures dark |

---

## ✍️ Typographie

Fichier : `lib/shared/theme/app_theme.dart` → classe `AppTextStyles`

### Polices
- **Cairo** → Arabe (RTL) — `AppTextStyles.fontAr`
- **Poppins** → Français (LTR) — `AppTextStyles.fontFr`

> La police est sélectionnée automatiquement selon la locale active dans `main.dart`.

### Styles disponibles

#### Display (grands titres)
```dart
AppTextStyles.displayLarge   // 32px, bold, -0.5 spacing
AppTextStyles.displayMedium  // 26px, bold, -0.3 spacing
```

#### Headlines
```dart
AppTextStyles.headlineLarge  // 22px, bold
AppTextStyles.headlineMedium // 18px, semibold
AppTextStyles.headlineSmall  // 16px, semibold
```

#### Body
```dart
AppTextStyles.bodyLarge      // 16px, regular, height 1.6
AppTextStyles.bodyMedium     // 14px, regular, height 1.6
AppTextStyles.bodySmall      // 12px, regular, height 1.5
```

#### Labels
```dart
AppTextStyles.labelLarge     // 14px, semibold, +0.1 spacing
AppTextStyles.labelMedium    // 12px, medium,   +0.2 spacing
AppTextStyles.labelSmall     // 11px, medium,   +0.5 spacing
```

#### Spéciaux
```dart
AppTextStyles.articleTitle   // 15px, bold — titres dans le feed (FR)
AppTextStyles.articleTitleAr // 16px, bold, Cairo — titres arabes
AppTextStyles.meta           // 11px — dates, sources, metadata
AppTextStyles.buttonLarge    // 16px, semibold — grands boutons
AppTextStyles.buttonMedium   // 14px, semibold
AppTextStyles.buttonSmall    // 12px, semibold
```

#### Usage type
```dart
Text(
  'Titre article',
  style: AppTextStyles.articleTitle.copyWith(
    color: AppColors.textPrimary,
  ),
)
```

---

## 📐 Spacing & Layout

Fichier : `lib/shared/theme/app_theme.dart` → classe `AppSpacing`

```dart
AppSpacing.xxs  = 2.0
AppSpacing.xs   = 4.0
AppSpacing.sm   = 8.0
AppSpacing.md   = 12.0
AppSpacing.lg   = 16.0   ← padding standard horizontal
AppSpacing.xl   = 20.0
AppSpacing.xxl  = 24.0
AppSpacing.xxxl = 32.0
AppSpacing.huge = 48.0
```

#### EdgeInsets prêts à l'emploi
```dart
AppSpacing.pagePadding  // horizontal: 16, vertical: 24 — padding des screens
AppSpacing.cardPadding  // all: 16 — padding interne des cards
AppSpacing.chipPadding  // horizontal: 12, vertical: 4 — padding des chips
```

---

## 🔲 Border Radius

Fichier : `lib/shared/theme/app_theme.dart` → classe `AppRadius`

```dart
AppRadius.xs   = 4.0
AppRadius.sm   = 8.0
AppRadius.md   = 12.0   ← cards standard
AppRadius.lg   = 16.0
AppRadius.xl   = 20.0
AppRadius.xxl  = 24.0
AppRadius.full = 999.0  ← chips, badges ronds
```

#### BorderRadius prêts à l'emploi
```dart
AppRadius.cardRadius    // all: 12 — toutes les cards
AppRadius.buttonRadius  // all: 8  — tous les boutons
AppRadius.chipRadius    // all: 999 — chips et badges
AppRadius.imageRadius   // all: 12 — images dans cards
AppRadius.bottomSheet   // top: 24 — tous les bottom sheets
```

---

## 🌑 Ombres

```dart
AppShadows.card       // ombre légère pour les cards
AppShadows.cardHover  // ombre plus prononcée (état hover/tap)
AppShadows.bottomNav  // ombre pour la bottom navigation bar
```

---

## 🧭 Navigation — GoRouter

Fichier : `lib/app/router.dart`

### Noms de routes disponibles
```dart
AppRoutes.splash          = '/'
AppRoutes.onboarding      = '/onboarding'
AppRoutes.feed            = '/feed'
AppRoutes.articleWebView  = '/article'
AppRoutes.agencyRegister  = '/agency/register'
AppRoutes.agencyLogin     = '/agency/login'
AppRoutes.agencyPending   = '/agency/pending'
AppRoutes.agencyDashboard = '/agency/dashboard'
AppRoutes.agencyPublish   = '/agency/publish'
AppRoutes.agencyEditArticle = '/agency/edit'
AppRoutes.agencyProfile   = '/agency/profile'
AppRoutes.adminDashboard  = '/admin'
AppRoutes.adminValidation = '/admin/validation'
AppRoutes.adminReports    = '/admin/reports'
AppRoutes.adminCategories = '/admin/categories'
AppRoutes.adminAgencies   = '/admin/agencies'
```

### Navigation
```dart
// Aller vers une route
context.go(AppRoutes.feed);
context.push(AppRoutes.agencyPublish);

// Passer des données à ArticleWebView
context.push(AppRoutes.articleWebView, extra: {
  'url': article.sourceUrl,
  'title': article.title,
  'articleId': article.id,
});

// Passer un articleId à EditArticle
context.push(AppRoutes.agencyEditArticle, extra: article.id);
```

---

## 🔌 Providers Riverpod — Comment les utiliser

Fichier : `lib/features/feed/providers/feed_providers.dart`

### Dans un widget ConsumerWidget
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // ── Lire l'état ───────────────────────────────────────
    final locale   = ref.watch(appLocaleProvider);
    final isAdmin  = ref.watch(isAdminProvider);
    final isAgency = ref.watch(isAgencyProvider);

    // ── Feed ──────────────────────────────────────────────
    final articlesAsync = ref.watch(feedArticlesProvider);
    final categories    = ref.watch(categoriesProvider);
    final selectedDate  = ref.watch(selectedDateProvider);
    final selectedCat   = ref.watch(selectedCategoryProvider);

    // ── Agence connectée ──────────────────────────────────
    final agencyAsync = ref.watch(currentAgencyProvider);

    // ── Réaction sur un article ───────────────────────────
    final myReaction = ref.watch(myReactionProvider('article-uuid'));

    // ── Admin ─────────────────────────────────────────────
    final stats           = ref.watch(adminStatsProvider);
    final pendingAgencies = ref.watch(pendingAgenciesProvider);
    final pendingReports  = ref.watch(pendingReportsProvider);

    // ── Modifier l'état ───────────────────────────────────
    // Changer la date sélectionnée
    ref.read(selectedDateProvider.notifier).state = DateTime.now();

    // Changer la catégorie filtre
    ref.read(selectedCategoryProvider.notifier).state = 'category-uuid';

    // Changer la langue
    ref.read(appLocaleProvider.notifier).state = const Locale('ar');

    // ── Consommer un AsyncValue ───────────────────────────
    return articlesAsync.when(
      data: (articles) => ArticlesList(articles: articles),
      loading: () => const ShimmerFeedLoader(),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
    );
  }
}
```

---

## 📋 Modèles de données

### ArticleModel — champs disponibles
```dart
article.id               // String — UUID
article.title            // String — titre de l'article
article.sourceUrl        // String — URL à ouvrir dans WebView
article.coverImageUrl    // String? — URL image de couverture
article.language         // ArticleLanguage.ar | .fr
article.publishedAt      // DateTime
article.agencyName       // String? — nom de l'agence source
article.agencyLogoUrl    // String? — logo de l'agence
article.categoryNameAr   // String? — "سياسة"
article.categoryNameFr   // String? — "Politique"
article.categoryIcon     // String? — "🏛️"
article.categoryColor    // String? — "#EF4444"
article.reactionCounts   // ReactionCounts

// Helpers
article.isRtl            // bool — true si langue arabe
article.categoryName(locale)  // name_ar ou name_fr selon locale
article.reactionCounts.total  // int — total toutes réactions
```

### AgencyModel — champs disponibles
```dart
agency.id             // String
agency.name           // String
agency.email          // String
agency.logoUrl        // String?
agency.websiteUrl     // String
agency.mediaType      // MediaType enum
agency.status         // AgencyStatus enum
agency.rejectReason   // String? — raison du rejet si rejeté
agency.createdAt      // DateTime
agency.validatedAt    // DateTime?

// Helpers
agency.status.label     // "En attente" | "Approuvée" | ...
agency.status.canPublish // bool
```

### CategoryModel
```dart
category.id           // String
category.nameAr       // "سياسة"
category.nameFr       // "Politique"
category.icon         // "🏛️"
category.colorHex     // "#EF4444"
category.displayOrder // int
category.isActive     // bool

// Helper
category.name(locale) // retourne nameAr ou nameFr
```

### EmojiType — réactions
```dart
EmojiType.like   // 👍  couleur: AppColors.emojiLike
EmojiType.wow    // 😮  couleur: AppColors.emojiWow
EmojiType.sad    // 😢  couleur: AppColors.emojiSad
EmojiType.angry  // 😡  couleur: AppColors.emojiAngry
EmojiType.fire   // 🔥  couleur: AppColors.emojiFire

// Helpers
emoji.emoji  // "👍"
emoji.label  // "J'aime"
```

### ReportReason — raisons de signalement
```dart
ReportReason.fakeNews       // .labelFr = "Fausse information"
ReportReason.inappropriate  // .labelFr = "Contenu inapproprié"
ReportReason.brokenLink     // .labelFr = "Lien cassé"
ReportReason.duplicate      // .labelFr = "Article dupliqué"
ReportReason.other          // .labelFr = "Autre"

// Chaque raison a .labelFr et .labelAr
```

---

## 🔧 Appels backend — Exemples pratiques

### Charger les articles du jour
```dart
final repo = ref.read(feedRepositoryProvider);
final articles = await repo.getArticlesByDate(DateTime.now());
```

### Réagir à un article
```dart
final repo = ref.read(reactionRepositoryProvider);
await repo.react(articleId: article.id, emoji: EmojiType.fire);
// Invalider pour rafraîchir le compteur
ref.invalidate(myReactionProvider(article.id));
ref.invalidate(feedArticlesProvider);
```

### Signaler un article
```dart
final repo = ref.read(reportRepositoryProvider);
try {
  await repo.reportArticle(
    articleId: article.id,
    reason: ReportReason.fakeNews,
  );
  // Afficher confirmation
} on AppError catch (e) {
  if (e.code == 'ALREADY_REPORTED') {
    // Afficher "Vous avez déjà signalé cet article"
  }
}
```

### Publier un article (agence)
```dart
final repo = ref.read(agencyRepositoryProvider);
await repo.publishArticle(
  agencyId: agency.id,
  title: titleController.text,
  sourceUrl: urlController.text,
  language: 'ar', // ou 'fr'
  categoryId: selectedCategoryId,
  coverImageUrl: uploadedImageUrl,
);
ref.invalidate(myArticlesProvider(agency.id));
```

### Valider une agence (admin)
```dart
final repo = ref.read(adminRepositoryProvider);
await repo.approveAgency(agencyId);
ref.invalidate(pendingAgenciesProvider);
```

---

## 🗂️ Structure des fichiers

```
lib/
├── main.dart
├── app/
│   └── router.dart                    ← GoRouter + AppRoutes
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         ← Toutes les constantes
│   │   └── env.dart                   ← Clés Supabase (généré)
│   ├── errors/
│   │   └── app_error.dart             ← AppError + Result<T>
│   └── utils/
│       ├── device_id.dart             ← DeviceIdService
│       └── validators.dart            ← Validators (forms)
├── features/
│   ├── feed/
│   │   ├── data/feed_repository.dart
│   │   ├── providers/feed_providers.dart  ← TOUS les providers
│   │   └── ui/                        ← À créer : FeedScreen, ArticleCard
│   ├── webview/
│   │   └── ui/                        ← À créer : ArticleWebViewScreen
│   ├── reactions/
│   │   ├── data/reaction_repository.dart
│   │   └── ui/                        ← À créer : EmojiPanel
│   ├── reports/
│   │   └── data/report_repository.dart
│   ├── agency/
│   │   ├── data/agency_repository.dart
│   │   └── ui/                        ← À créer : Register, Login, Dashboard...
│   └── admin/
│       ├── data/admin_repository.dart
│       └── ui/                        ← À créer : Validation, Reports, Categories
└── shared/
    ├── models/
    │   ├── article_model.dart
    │   ├── agency_model.dart
    │   ├── models.dart               ← Category, Reaction, Report
    │   └── *.freezed.dart            ← Générés (build_runner)
    ├── theme/
    │   └── app_theme.dart            ← AppColors, AppTextStyles, AppSpacing...
    └── widgets/                      ← À créer : widgets partagés
```

---

## 📱 Écrans à implémenter (frontend)

> Tous les repositories, providers et modèles sont prêts.  
> Le frontend doit uniquement créer les fichiers UI dans `lib/features/**/ui/`.

### 🟢 Espace Lecteur (Public)

| Écran | Fichier à créer | Provider à utiliser |
|---|---|---|
| Splash | `feed/ui/splash_screen.dart` | `authStateProvider` |
| Onboarding (choix langue) | `feed/ui/onboarding_screen.dart` | `appLocaleProvider` |
| Feed principal | `feed/ui/feed_screen.dart` | `feedArticlesProvider`, `categoriesProvider`, `selectedDateProvider` |
| Carte article | `feed/ui/article_card.dart` | `myReactionProvider` |
| WebView article | `webview/ui/article_webview_screen.dart` | `reactionRepositoryProvider`, `reportRepositoryProvider` |
| Panel réactions | `reactions/ui/emoji_panel.dart` | `reactionRepositoryProvider` |
| Bottom sheet signalement | `reports/ui/report_bottom_sheet.dart` | `reportRepositoryProvider` |

### 🔵 Espace Agence

| Écran | Fichier à créer | Provider à utiliser |
|---|---|---|
| Inscription | `agency/ui/agency_register_screen.dart` | `agencyRepositoryProvider` |
| Login | `agency/ui/agency_login_screen.dart` | `agencyRepositoryProvider` |
| Attente validation | `agency/ui/agency_pending_screen.dart` | `currentAgencyProvider` |
| Dashboard | `agency/ui/agency_dashboard_screen.dart` | `myArticlesProvider`, `currentAgencyProvider` |
| Publier article | `agency/ui/publish_article_screen.dart` | `agencyRepositoryProvider`, `categoriesProvider` |
| Modifier article | `agency/ui/edit_article_screen.dart` | `agencyRepositoryProvider` |
| Profil | `agency/ui/agency_profile_screen.dart` | `currentAgencyProvider` |

### 🔴 Espace Admin

| Écran | Fichier à créer | Provider à utiliser |
|---|---|---|
| Dashboard | `admin/ui/admin_dashboard_screen.dart` | `adminStatsProvider` |
| Validation agences | `admin/ui/agency_validation_screen.dart` | `pendingAgenciesProvider`, `adminRepositoryProvider` |
| Signalements | `admin/ui/reports_management_screen.dart` | `pendingReportsProvider`, `adminRepositoryProvider` |
| Catégories | `admin/ui/categories_management_screen.dart` | `categoriesProvider`, `adminRepositoryProvider` |
| Liste agences | `admin/ui/agencies_list_screen.dart` | `adminRepositoryProvider` |

---

## 🧩 Composants UI recommandés à créer

### ArticleCard (feed)
```
┌─────────────────────────────────┐
│  [Image couverture 16:9]        │
│                                 │
│  [🏛️ Politique]  [⏰ 14:32]    │
│                                 │
│  Titre de l'article en arabe    │
│  أو بالفرنسية                  │
│                                 │
│  [Logo] Nom Agence              │
│                                 │
│  👍12  😮4  🔥8    [⚠️ Signaler]│
└─────────────────────────────────┘
```
- `borderRadius: AppRadius.cardRadius`
- `shadow: AppShadows.card`
- Titre en `AppTextStyles.articleTitle` ou `.articleTitleAr` selon `article.isRtl`
- Date en `AppTextStyles.meta` couleur `AppColors.textTertiary`

### DateBanner (bandeau de sélection de date)
```
[Aujourd'hui] [Hier] [15 jan] [14 jan] [13 jan] [12 jan] [📅]
```
- ScrollView horizontal
- Fond `AppColors.primarySurface` sur la date sélectionnée
- Texte sélectionné `AppColors.primary`

### CategoryChip
```dart
FilterChip(
  label: Text(category.name(locale)),
  avatar: Text(category.icon),
  selected: isSelected,
  selectedColor: Color(int.parse(category.colorHex.replaceAll('#', '0xFF'))),
)
```

### EmojiPanel (bottom sheet ou popup)
```
[ 👍 ]  [ 😮 ]  [ 😢 ]  [ 😡 ]  [ 🔥 ]
 12       4       0       2       8
```
- Emoji sélectionné : fond `AppColors.primarySurface`, bordure `AppColors.primary`
- Tap = toggle (si même emoji → supprimer la réaction)

### StatusBadge (agence)
```dart
// Utiliser agency.status pour déterminer couleur et texte
Container(
  padding: AppSpacing.chipPadding,
  decoration: BoxDecoration(
    color: _statusColor(agency.status).withOpacity(0.1),
    borderRadius: AppRadius.chipRadius,
    border: Border.all(color: _statusColor(agency.status)),
  ),
  child: Text(agency.status.label),
)
```

---

## ✅ Validators — Formulaires

Fichier : `lib/core/utils/validators.dart`

```dart
TextFormField(
  validator: Validators.email,          // email
  validator: Validators.password,       // password (min 8 chars)
  validator: Validators.agencyName,     // nom agence (min 2 chars)
  validator: Validators.websiteUrl,     // URL (https://)
  validator: Validators.articleTitle,   // titre article (min 3 chars)
  validator: Validators.articleUrl,     // URL article (https://)
  validator: (v) => Validators.required(v, message: 'Champ requis'),
)
```

---

## 🌐 Gestion RTL

L'app bascule automatiquement en RTL quand la locale est `ar`.

Pour un widget spécifique à directionner manuellement :
```dart
Directionality(
  textDirection: article.isRtl ? TextDirection.rtl : TextDirection.ltr,
  child: Text(article.title, style: AppTextStyles.articleTitleAr),
)
```

Pour les marges symétriques (RTL-safe) :
```dart
// ✅ Correct — s'adapte au sens du texte
padding: const EdgeInsetsDirectional.only(start: 16, end: 8)

// ❌ À éviter pour RTL
padding: const EdgeInsets.only(left: 16, right: 8)
```

---

## 🐛 Gestion des erreurs

```dart
try {
  await repo.someAction();
} on AppError catch (e) {
  // e.message → message lisible à afficher à l'utilisateur
  // e.code    → code pour traitement conditionnel
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

---

## 📡 Realtime — Feed auto-refresh

Le feed peut écouter les nouveaux articles en temps réel :
```dart
// Dans un StreamProvider, utiliser :
feedRepositoryProvider.watchTodayArticles()

// Dans un widget :
ref.listen(feedArticlesProvider, (prev, next) {
  // Le feed se met à jour automatiquement
});
```

---

## 🔑 Rôles utilisateur

```dart
// Vérifier le rôle dans un widget
final isAdmin  = ref.watch(isAdminProvider);
final isAgency = ref.watch(isAgencyProvider);
final role     = ref.watch(currentUserRoleProvider); // 'admin' | 'agency' | 'anonymous'

// Affichage conditionnel
if (isAdmin) AdminWidget()
else if (isAgency) AgencyWidget()
else ReaderWidget()
```

---

## 📦 Packages installés

| Package | Version | Usage |
|---|---|---|
| `supabase_flutter` | ^2.5.0 | Client Supabase (DB, Auth, Storage, Realtime) |
| `flutter_riverpod` | ^2.5.1 | State management |
| `go_router` | ^13.2.0 | Navigation déclarative |
| `webview_flutter` | ^4.7.0 | Affichage articles dans l'app |
| `cached_network_image` | ^3.3.1 | Images avec cache automatique |
| `shimmer` | ^3.0.0 | Skeleton loading |
| `image_picker` | ^1.1.2 | Upload images (couverture, logo) |
| `shared_preferences` | ^2.2.3 | Device ID, langue, onboarding |
| `uuid` | ^4.4.0 | Génération Device ID |
| `intl` | ^0.19.0 | Formatage dates, i18n |
| `share_plus` | ^9.0.0 | Partager un article |
| `connectivity_plus` | ^6.0.3 | Détecter état réseau |
| `gap` | ^3.0.1 | SizedBox simplifié |
| `freezed` | ^2.5.2 | Modèles immutables |
| `equatable` | ^2.0.5 | Comparaison d'objets |
| `logger` | ^2.4.0 | Logs de debug |

---

*Projet Dev Mobile — SupNum*
