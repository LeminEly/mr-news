import 'package:flutter/material.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

/// Modèle statique pour l’espace agence (mock — pas de backend).
class MockArticle {
  const MockArticle({
    required this.id,
    required this.title,
    required this.sourceUrl,
    this.coverImageUrl,
    required this.language,
    required this.publishedAt,
    this.agencyName,
    this.agencyLogoUrl,
    this.categoryNameAr,
    this.categoryNameFr,
    this.categoryIcon,
    this.categoryColor,
    this.lastModifiedAt,
    this.mockViews,
    this.mockReactions,
  });

  final String id;
  final String title;
  final String sourceUrl;
  final String? coverImageUrl;
  final String language;
  final DateTime publishedAt;
  final String? agencyName;
  final String? agencyLogoUrl;
  final String? categoryNameAr;
  final String? categoryNameFr;
  final String? categoryIcon;
  /// Référence design (ex: politique) — résolu vers [categoryDisplayColor].
  final String? categoryColor;
  final DateTime? lastModifiedAt;
  final int? mockViews;
  final int? mockReactions;

  bool get isRtl => language == 'ar';

  int get views => mockViews ?? (200 + id.hashCode.abs() % 400);

  int get reactions => mockReactions ?? (30 + id.hashCode.abs() % 80);

  /// Couleur catégorie depuis le design system (pas de hex dans les widgets).
  Color get categoryDisplayColor {
    final fr = categoryNameFr?.toLowerCase() ?? '';
    if (fr.contains('politique')) return AppColors.catPolitique;
    if (fr.contains('économie') || fr.contains('economie')) {
      return AppColors.catEconomie;
    }
    if (fr.contains('sport')) return AppColors.catSport;
    if (fr.contains('techno')) return AppColors.catTechno;
    if (fr.contains('société') || fr.contains('societe')) {
      return AppColors.catSociete;
    }
    if (fr.contains('santé') || fr.contains('sante')) return AppColors.catSante;
    if (fr.contains('culture')) return AppColors.catCulture;
    if (fr.contains('international')) return AppColors.catInternational;
    return AppColors.primary;
  }

  MockArticle copyWith({
    String? id,
    String? title,
    String? sourceUrl,
    String? coverImageUrl,
    String? language,
    DateTime? publishedAt,
    String? agencyName,
    String? agencyLogoUrl,
    String? categoryNameAr,
    String? categoryNameFr,
    String? categoryIcon,
    String? categoryColor,
    DateTime? lastModifiedAt,
    int? mockViews,
    int? mockReactions,
  }) {
    return MockArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      language: language ?? this.language,
      publishedAt: publishedAt ?? this.publishedAt,
      agencyName: agencyName ?? this.agencyName,
      agencyLogoUrl: agencyLogoUrl ?? this.agencyLogoUrl,
      categoryNameAr: categoryNameAr ?? this.categoryNameAr,
      categoryNameFr: categoryNameFr ?? this.categoryNameFr,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      mockViews: mockViews ?? this.mockViews,
      mockReactions: mockReactions ?? this.mockReactions,
    );
  }
}

/// Catégorie éditoriale (couleurs = [AppColors] uniquement).
class AgencyCategoryOption {
  const AgencyCategoryOption({
    required this.id,
    required this.labelFr,
    required this.icon,
    required this.color,
    required this.nameAr,
  });

  final String id;
  final String labelFr;
  final String icon;
  final Color color;
  final String nameAr;
}

const List<AgencyCategoryOption> kAgencyCategories = [
  AgencyCategoryOption(
    id: 'politique',
    labelFr: 'Politique',
    icon: '🏛️',
    color: AppColors.catPolitique,
    nameAr: 'سياسة',
  ),
  AgencyCategoryOption(
    id: 'economie',
    labelFr: 'Économie',
    icon: '📈',
    color: AppColors.catEconomie,
    nameAr: 'اقتصاد',
  ),
  AgencyCategoryOption(
    id: 'sport',
    labelFr: 'Sport',
    icon: '⚽',
    color: AppColors.catSport,
    nameAr: 'رياضة',
  ),
  AgencyCategoryOption(
    id: 'techno',
    labelFr: 'Technologie',
    icon: '💻',
    color: AppColors.catTechno,
    nameAr: 'تكنولوجيا',
  ),
  AgencyCategoryOption(
    id: 'societe',
    labelFr: 'Société',
    icon: '👥',
    color: AppColors.catSociete,
    nameAr: 'مجتمع',
  ),
  AgencyCategoryOption(
    id: 'sante',
    labelFr: 'Santé',
    icon: '🏥',
    color: AppColors.catSante,
    nameAr: 'صحة',
  ),
  AgencyCategoryOption(
    id: 'culture',
    labelFr: 'Culture',
    icon: '🎭',
    color: AppColors.catCulture,
    nameAr: 'ثقافة',
  ),
  AgencyCategoryOption(
    id: 'international',
    labelFr: 'International',
    icon: '🌍',
    color: AppColors.catInternational,
    nameAr: 'دولي',
  ),
];

AgencyCategoryOption? categoryOptionForArticle(MockArticle a) {
  final fr = a.categoryNameFr?.trim() ?? '';
  for (final c in kAgencyCategories) {
    if (fr == c.labelFr) return c;
  }
  return null;
}

/// Articles de démonstration (dates relatives au chargement).
List<MockArticle> get mockArticles {
  final now = DateTime.now();
  const offsets = <Duration>[
    Duration(hours: 2),
    Duration(hours: 5),
    Duration(days: 1),
    Duration(days: 2),
    Duration(days: 3),
  ];
  return [
    MockArticle(
      id: '1',
      title: 'الحكومة الموريتانية تطلق مشروعاً لتطوير البنية التحتية',
      sourceUrl: 'https://mauritanie-news.mr/article/1',
      coverImageUrl: 'https://picsum.photos/seed/nouakchott1/400/200',
      language: 'ar',
      publishedAt: now.subtract(offsets[0]),
      agencyName: 'وكالة موريتانيا للأنباء',
      agencyLogoUrl: 'https://picsum.photos/seed/agency1/100/100',
      categoryNameAr: 'سياسة',
      categoryNameFr: 'Politique',
      categoryIcon: '🏛️',
      categoryColor: 'cat_politique',
      mockViews: 324,
      mockReactions: 48,
    ),
    MockArticle(
      id: '2',
      title: 'La Mauritanie renforce ses partenariats économiques avec l\'UE',
      sourceUrl: 'https://mauritanie-news.mr/article/2',
      coverImageUrl: 'https://picsum.photos/seed/economie2/400/200',
      language: 'fr',
      publishedAt: now.subtract(offsets[1]),
      agencyName: 'Agence Mauritanie Presse',
      agencyLogoUrl: 'https://picsum.photos/seed/agency2/100/100',
      categoryNameAr: 'اقتصاد',
      categoryNameFr: 'Économie',
      categoryIcon: '📈',
      categoryColor: 'cat_economie',
      mockViews: 412,
      mockReactions: 62,
    ),
    MockArticle(
      id: '3',
      title: 'المنتخب الموريتاني يفوز في تصفيات كأس أفريقيا',
      sourceUrl: 'https://mauritanie-news.mr/article/3',
      coverImageUrl: 'https://picsum.photos/seed/sport3/400/200',
      language: 'ar',
      publishedAt: now.subtract(offsets[2]),
      agencyName: 'وكالة الرياضة الموريتانية',
      agencyLogoUrl: 'https://picsum.photos/seed/agency3/100/100',
      categoryNameAr: 'رياضة',
      categoryNameFr: 'Sport',
      categoryIcon: '⚽',
      categoryColor: 'cat_sport',
      mockViews: 891,
      mockReactions: 120,
    ),
    MockArticle(
      id: '4',
      title:
          'Lancement du programme national de connectivité numérique en Mauritanie',
      sourceUrl: 'https://mauritanie-news.mr/article/4',
      coverImageUrl: 'https://picsum.photos/seed/techno4/400/200',
      language: 'fr',
      publishedAt: now.subtract(offsets[3]),
      agencyName: 'Agence Mauritanie Presse',
      agencyLogoUrl: 'https://picsum.photos/seed/agency2/100/100',
      categoryNameAr: 'تكنولوجيا',
      categoryNameFr: 'Technologie',
      categoryIcon: '💻',
      categoryColor: 'cat_techno',
      mockViews: 256,
      mockReactions: 34,
    ),
    MockArticle(
      id: '5',
      title: 'مبادرة جديدة لدعم المرأة في سوق العمل الموريتاني',
      sourceUrl: 'https://mauritanie-news.mr/article/5',
      coverImageUrl: 'https://picsum.photos/seed/societe5/400/200',
      language: 'ar',
      publishedAt: now.subtract(offsets[4]),
      agencyName: 'وكالة موريتانيا للأنباء',
      agencyLogoUrl: 'https://picsum.photos/seed/agency1/100/100',
      categoryNameAr: 'مجتمع',
      categoryNameFr: 'Société',
      categoryIcon: '👥',
      categoryColor: 'cat_societe',
      mockViews: 178,
      mockReactions: 41,
    ),
  ];
}
