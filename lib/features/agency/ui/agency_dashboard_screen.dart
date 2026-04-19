import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/mock_article.dart';
import 'package:mauritanie_news/features/agency/ui/publish_article_screen.dart';
import 'package:mauritanie_news/features/agency/ui/widgets/agency_drawer.dart';
import 'package:mauritanie_news/features/agency/ui/widgets/article_card_agency.dart';
import 'package:mauritanie_news/features/agency/ui/widgets/empty_state_widget.dart';
import 'package:mauritanie_news/features/agency/ui/widgets/stats_card.dart';

/// Tableau de bord agence (données mockées — prêt pour Supabase).
class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<MockArticle> _articles;
  String? _filterCategoryId;

  late final AnimationController _appBarGradientCtrl;
  late final List<AnimationController> _statControllers;

  @override
  void initState() {
    super.initState();
    _articles = List<MockArticle>.from(mockArticles);

    _appBarGradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _statControllers = List<AnimationController>.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      ),
    );

    for (var i = 0; i < _statControllers.length; i++) {
      Future<void>.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) _statControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _appBarGradientCtrl.dispose();
    for (final c in _statControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<MockArticle> get _visibleArticles {
    if (_filterCategoryId == null) return _articles;
    return _articles.where((a) {
      final opt = categoryOptionForArticle(a);
      return opt?.id == _filterCategoryId;
    }).toList();
  }

  Future<void> _openPublish() async {
    // TODO: connect to Supabase — vérifier session agence avant publication.
    final created = await Navigator.of(context).push<MockArticle>(
      MaterialPageRoute<MockArticle>(
        builder: (_) => const PublishArticleScreen(),
      ),
    );
    if (created != null && mounted) {
      setState(() {
        _articles = [created, ..._articles];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleArticles;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AgencyDrawer(
        selectedItem: AgencyDrawerSelection.dashboard,
        onClose: () => Navigator.of(context).maybePop(),
        onDashboard: () {},
        onPublish: _openPublish,
        onProfile: () {
          // TODO: connect to Supabase — charger le profil agence.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil agence (mock)',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
              backgroundColor: AppColors.info,
            ),
          );
        },
        onSettings: () {
          // TODO: connect to Supabase — préférences agence.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Paramètres (mock)',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
              backgroundColor: AppColors.info,
            ),
          );
        },
        onLogout: () {
          // TODO: connect to Supabase — signOut.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Déconnexion (mock)',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _appBarGradientCtrl,
          builder: (context, _) {
            final t = CurvedAnimation(parent: _appBarGradientCtrl, curve: Curves.easeInOut).value;
            return AppBar(
              iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.lerp(AppColors.primary, AppColors.secondary, t)!,
                      Color.lerp(AppColors.secondary, AppColors.primary, t)!,
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                'Tableau de Bord',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textOnPrimary),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _openPublish,
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surface,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: 'https://picsum.photos/200',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.surfaceVariant,
                          highlightColor: AppColors.surface,
                          child: Container(
                            width: 36,
                            height: 36,
                            color: AppColors.surfaceVariant,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Filtrer par catégorie',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'Tous',
                          selected: _filterCategoryId == null,
                          selectedColor: AppColors.primary,
                          onTap: () => setState(() => _filterCategoryId = null),
                        ),
                        ...kAgencyCategories.take(5).map((c) {
                          final sel = _filterCategoryId == c.id;
                          return _FilterChip(
                            label: '${c.icon} ${c.labelFr}',
                            selected: sel,
                            selectedColor: c.color,
                            onTap: () => setState(() => _filterCategoryId = c.id),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: EmptyStateWidget(onPublishPressed: _openPublish),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = visible[index];
                    return _StaggeredArticleRow(
                      index: index,
                      article: a,
                      onDeleted: () {
                        setState(() {
                          _articles.removeWhere((e) => e.id == a.id);
                        });
                      },
                      onUpdated: (updated) {
                        setState(() {
                          final i = _articles.indexWhere((e) => e.id == updated.id);
                          if (i >= 0) _articles[i] = updated;
                        });
                      },
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = <({String title, String value, IconData icon, Color color})>[
      (title: 'Articles publiés', value: '12', icon: Icons.article_outlined, color: AppColors.primary),
      (title: 'Total réactions', value: '248', icon: Icons.favorite_border, color: AppColors.accent),
      (title: 'Vues estimées', value: '3.2k', icon: Icons.visibility_outlined, color: AppColors.info),
      (title: 'Ce mois-ci', value: '5', icon: Icons.trending_up, color: AppColors.success),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List<Widget>.generate(4, (i) {
            final s = stats[i];
            return SizedBox(
              width: w,
              child: StatsCard(
                title: s.title,
                value: s.value,
                icon: s.icon,
                accentColor: s.color,
                animation: CurvedAnimation(parent: _statControllers[i], curve: Curves.easeOutCubic),
              ),
            );
          }),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? selectedColor : AppColors.surfaceVariant,
        borderRadius: AppRadius.chipRadius,
        child: InkWell(
          borderRadius: AppRadius.chipRadius,
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.chipPadding,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredArticleRow extends StatefulWidget {
  const _StaggeredArticleRow({
    required this.index,
    required this.article,
    required this.onDeleted,
    required this.onUpdated,
  });

  final int index;
  final MockArticle article;
  final VoidCallback onDeleted;
  final ValueChanged<MockArticle> onUpdated;

  @override
  State<_StaggeredArticleRow> createState() => _StaggeredArticleRowState();
}

class _StaggeredArticleRowState extends State<_StaggeredArticleRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future<void>.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return ArticleCardAgency(
      article: widget.article,
      animation: anim,
      onDeleted: widget.onDeleted,
      onUpdated: widget.onUpdated,
    );
  }
}
