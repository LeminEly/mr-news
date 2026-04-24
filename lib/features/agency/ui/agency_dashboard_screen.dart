import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/publish_article_screen.dart';
import 'package:mauritanie_news/shared/widgets/agency/agency_drawer.dart';
import 'package:mauritanie_news/shared/widgets/agency/article_card_agency.dart';
import 'package:mauritanie_news/shared/widgets/agency/empty_state_widget.dart';
import 'package:mauritanie_news/shared/widgets/agency/stats_card.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/article_model.dart';
import 'package:mauritanie_news/shared/models/category_model.dart';
import 'package:mauritanie_news/features/agency/ui/edit_article_screen.dart';
import 'package:mauritanie_news/features/agency/ui/agency_profile.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/features/agency/ui/agency_login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tableau de bord agence (Supabase).
class AgencyDashboardScreen extends ConsumerStatefulWidget {
  const AgencyDashboardScreen({super.key, required this.agency});

  final AgencyModel? agency;

  @override
  ConsumerState<AgencyDashboardScreen> createState() =>
      _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends ConsumerState<AgencyDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Copie mutable pour rafraîchir logo / infos après le profil.
  AgencyModel? _agency;

  List<ArticleModel> _articles = const [];
  List<CategoryModel> _categories = const [];
  bool _loading = true;
  String? _filterCategoryId;

  late final AnimationController _appBarGradientCtrl;
  late final List<AnimationController> _statControllers;

  @override
  void initState() {
    super.initState();
    _agency = widget.agency;

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

    Future<void>.microtask(_load);
  }

  @override
  void didUpdateWidget(covariant AgencyDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.agency != oldWidget.agency) {
      _agency = widget.agency;
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

  List<ArticleModel> get _visibleArticles {
    if (_filterCategoryId == null) return _articles;
    return _articles.where((a) {
      return a.categoryId == _filterCategoryId;
    }).toList();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final agencyId = _agency?.id;
      if (agencyId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final repo = ref.read(agencyRepositoryProvider);
      final categories = await repo.getCategories();
      final articles = await repo.getMyArticles(agencyId);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _articles = articles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Erreur de chargement',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  Future<void> _openPublish() async {
    final agency = _agency;
    if (agency == null || agency.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Profil agence introuvable',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PublishArticleScreen(agency: agency),
      ),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openProfile() async {
    final agency = _agency;
    if (agency == null) return;
    final updated = await Navigator.of(context).push<AgencyModel?>(
      MaterialPageRoute(
        builder: (_) => AgencyProfileScreen(agency: agency),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _agency = updated);
    }
  }

  Widget _buildAppBarAvatar() {
    final url = (_agency?.logoUrl ?? '').trim();
    if (url.isEmpty) {
      return const Icon(
        Icons.business,
        color: AppColors.primary,
        size: 20,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
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
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text(
          'Déconnexion',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Déconnexion',
              style: AppTextStyles.buttonMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _logout();
  }

  Future<void> _logout() async {
    try {
      await AgencyAuthService(Supabase.instance.client).logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AgencyLoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Erreur de déconnexion',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
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
        agency: _agency,
        onClose: () => Navigator.of(context).maybePop(),
        onDashboard: () {},
        onPublish: _openPublish,
        onProfile: _openProfile,
        onLogout: _confirmLogout,
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
                      child: _buildAppBarAvatar(),
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
                        ..._categories.map((c) {
                          final sel = _filterCategoryId == c.id;
                          final locale =
                              Localizations.localeOf(context).languageCode;
                          return _FilterChip(
                            label: '${c.icon} ${c.name(locale)}',
                            selected: sel,
                            selectedColor: AppColors.surfaceVariant,
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
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (visible.isEmpty)
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
                    CategoryModel? category;
                    if (a.categoryId != null) {
                      for (final c in _categories) {
                        if (c.id == a.categoryId) {
                          category = c;
                          break;
                        }
                      }
                    }
                    return _StaggeredArticleRow(
                      index: index,
                      article: a,
                      category: category,
                      onDeleted: () {
                        _load();
                      },
                      onEdit: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => EditArticleScreen(
                              article: a,
                              categories: _categories,
                            ),
                          ),
                        );
                        if (updated == true && mounted) await _load();
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
    final publishedCount = _articles.length;
    final stats = <({String title, String value, IconData icon, Color color})>[
      (title: 'Articles publiés', value: '$publishedCount', icon: Icons.article_outlined, color: AppColors.primary),
      (title: 'Total réactions', value: '—', icon: Icons.favorite_border, color: AppColors.accent),
      (title: 'Vues estimées', value: '—', icon: Icons.visibility_outlined, color: AppColors.info),
      (title: 'Ce mois-ci', value: '—', icon: Icons.trending_up, color: AppColors.success),
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
    required this.category,
    required this.onDeleted,
    required this.onEdit,
  });

  final int index;
  final ArticleModel article;
  final CategoryModel? category;
  final VoidCallback onDeleted;
  final VoidCallback onEdit;

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
      category: widget.category,
      animation: anim,
      onDeleted: widget.onDeleted,
      onEdit: widget.onEdit,
    );
  }
}
