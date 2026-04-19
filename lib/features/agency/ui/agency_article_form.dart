import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/mock_article.dart';

/// Mode du formulaire agence (publication ou édition).
enum AgencyFormMode { publish, edit }

/// Formulaire article (mock) — partagé publication / édition.
class AgencyArticleForm extends StatefulWidget {
  const AgencyArticleForm({
    super.key,
    required this.mode,
    this.initial,
    required this.onPrimarySuccess,
    this.onCancel,
  });

  final AgencyFormMode mode;
  final MockArticle? initial;
  final void Function(MockArticle article) onPrimarySuccess;
  final VoidCallback? onCancel;

  @override
  State<AgencyArticleForm> createState() => _AgencyArticleFormState();
}

class _AgencyArticleFormState extends State<AgencyArticleForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  late final String _heroId;
  XFile? _pickedFile;
  String? _coverNetworkUrl;
  String _language = 'fr';
  AgencyCategoryOption? _category = kAgencyCategories.first;

  bool _loading = false;
  bool _success = false;

  late final AnimationController _checkCtrl;

  static const String _staticAgencyName = 'Agence Mauritanie Presse';
  static const String _staticAgencyLogo = 'https://picsum.photos/seed/agency2/100/100';

  bool get _hasCover {
    if (!kIsWeb && _pickedFile != null) return true;
    final u = _coverNetworkUrl?.trim() ?? '';
    if (u.isNotEmpty) return true;
    final init = widget.initial?.coverImageUrl;
    return init != null && init.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _heroId = initial?.id ?? const Uuid().v4();
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _urlCtrl.text = initial.sourceUrl;
      _language = initial.language;
      _coverNetworkUrl = initial.coverImageUrl;
      _category = categoryOptionForArticle(initial) ?? kAgencyCategories.first;
    }

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  String? _validateTitle(String? v) {
    final t = v?.trim() ?? '';
    if (t.length < 3) return 'Minimum 3 caractères';
    return null;
  }

  String? _validateUrl(String? v) {
    final t = v?.trim() ?? '';
    if (!t.startsWith('https://')) return 'L’URL doit commencer par https://';
    return null;
  }

  Future<void> _pickImage() async {
    // TODO: connect to Supabase — upload fichier vers le storage après choix.
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _coverNetworkUrl = null;
      });
    }
  }

  Future<void> _promptCoverUrl() async {
    final ctrl = TextEditingController(text: _coverNetworkUrl ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
          title: Text(
            'Image depuis une URL',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'https://…'),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: Text('Valider', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnPrimary)),
            ),
          ],
        );
      },
    );
    if (ok == true && mounted) {
      final u = ctrl.text.trim();
      setState(() {
        _coverNetworkUrl = u.isEmpty ? null : u;
        _pickedFile = null;
      });
    }
    // Ne pas disposer tant que le TextField du dialogue peut encore être dans l’arbre
    // (sinon assertion '_dependents.isEmpty' au runtime).
    final toDispose = ctrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toDispose.dispose();
    });
  }

  void _clearCover() {
    setState(() {
      _pickedFile = null;
      _coverNetworkUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_hasCover) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'Ajoutez une image de couverture',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) return;

    setState(() {
      _loading = true;
      _success = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      _loading = false;
      _success = true;
    });
    await _checkCtrl.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final now = DateTime.now();
    final cat = _category!;
    final isEdit = widget.mode == AgencyFormMode.edit;
    final base = widget.initial;

    final coverResolved = () {
      if (!kIsWeb && _pickedFile != null) {
        return _coverNetworkUrl ??
            base?.coverImageUrl ??
            'https://picsum.photos/seed/$_heroId/400/200';
      }
      final net = _coverNetworkUrl?.trim();
      if (net != null && net.isNotEmpty) return net;
      return base?.coverImageUrl ?? 'https://picsum.photos/seed/$_heroId/400/200';
    }();

    final article = MockArticle(
      id: base?.id ?? _heroId,
      title: _titleCtrl.text.trim(),
      sourceUrl: _urlCtrl.text.trim(),
      coverImageUrl: coverResolved,
      language: _language,
      publishedAt: base?.publishedAt ?? now,
      agencyName: _staticAgencyName,
      agencyLogoUrl: _staticAgencyLogo,
      categoryNameAr: cat.nameAr,
      categoryNameFr: cat.labelFr,
      categoryIcon: cat.icon,
      categoryColor: cat.id,
      lastModifiedAt: isEdit ? now : null,
    );

    widget.onPrimarySuccess(article);
  }

  Widget _buildCoverPreview({bool useHero = false}) {
    final hasLocal = !kIsWeb && _pickedFile != null;
    final hasNet = _coverNetworkUrl != null && _coverNetworkUrl!.trim().isNotEmpty;
    final fallback = widget.initial?.coverImageUrl;

    Widget imageChild = hasLocal
        ? Image.file(
            File(_pickedFile!.path),
            fit: BoxFit.cover,
          )
        : hasNet
            ? CachedNetworkImage(
                imageUrl: _coverNetworkUrl!.trim(),
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceVariant,
                  highlightColor: AppColors.surface,
                  child: Container(color: AppColors.surfaceVariant),
                ),
              )
            : (fallback != null && fallback.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: fallback,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surfaceVariant,
                      highlightColor: AppColors.surface,
                      child: Container(color: AppColors.surfaceVariant),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceVariant,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 40),
                  );

    if (useHero) {
      imageChild = Hero(
        tag: 'cover_image_$_heroId',
        child: imageChild,
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppRadius.imageRadius,
            child: imageChild,
          ),
          if (hasLocal || hasNet)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.error),
                  onPressed: _clearCover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final cat = _category ?? kAgencyCategories.first;
    final dateStr = DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now());
    final titleStyle = _language == 'ar'
        ? AppTextStyles.articleTitleAr
        : AppTextStyles.articleTitle;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aperçu',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCoverPreview(useHero: true),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: AppSpacing.chipPadding,
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Text(
                '${cat.icon} ${_language == 'ar' ? cat.nameAr : cat.labelFr}',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: _language == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: Text(
              _titleCtrl.text.trim().isEmpty ? 'Titre de l’article…' : _titleCtrl.text.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: titleStyle.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$dateStr · $_staticAgencyName',
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final isEdit = widget.mode == AgencyFormMode.edit;
    final bg = isEdit ? AppColors.secondary : AppColors.primary;

    Widget content;
    if (_loading) {
      content = Shimmer.fromColors(
        baseColor: AppColors.primaryDark,
        highlightColor: AppColors.primaryLight,
        period: const Duration(milliseconds: 1100),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.8, color: AppColors.textOnPrimary),
        ),
      );
    } else if (_success) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
            child: const Icon(Icons.check_circle, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isEdit ? '💾 Sauvegarder les modifications' : '✅ Publier l’article',
            style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
          ),
        ],
      );
    } else {
      content = Text(
        isEdit ? '💾 Sauvegarder les modifications' : '✅ Publier l’article',
        style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_loading || _success) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: bg.withValues(alpha: 0.75),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informations principales',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _titleCtrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Titre de l’article *',
              hintText: 'Entrez un titre accrocheur…',
              alignLabelWithHint: true,
            ),
            validator: _validateTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _urlCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'URL de l’article *',
              hintText: 'https://votre-site.mr/article…',
              prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary),
              suffixIcon: TextButton(
                onPressed: () {
                  // TODO: connect to Supabase — ouvrir WebView d’aperçu réel.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Aperçu : ${_urlCtrl.text.trim().isEmpty ? "(vide)" : _urlCtrl.text.trim()}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
                      ),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                child: Text(
                  'Aperçu',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                ),
              ),
            ),
            keyboardType: TextInputType.url,
            validator: _validateUrl,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Image de couverture *',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.imageRadius,
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: _buildCoverPreview(useHero: false),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                  label: Text(
                    '📷 Choisir une image',
                    style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _promptCoverUrl,
                  icon: const Icon(Icons.link, color: AppColors.secondary),
                  label: Text(
                    '🔗 Depuis une URL',
                    style: AppTextStyles.buttonMedium.copyWith(color: AppColors.secondary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondary),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Classification',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Langue', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fr', label: Text('🇫🇷 Français')),
              ButtonSegment(value: 'ar', label: Text('🇲🇷 العربية')),
            ],
            selected: {_language},
            emptySelectionAllowed: false,
            onSelectionChanged: (s) {
              setState(() => _language = s.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.primary;
                return AppColors.surfaceVariant;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
                return AppColors.textSecondary;
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Catégorie', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, c) {
              final w = ((c.maxWidth - AppSpacing.md) / 2).clamp(120.0, double.infinity);
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: kAgencyCategories.map((e) {
                  final sel = _category?.id == e.id;
                  return SizedBox(
                    width: w,
                    child: FilterChip(
                      label: Text('${e.icon} ${e.labelFr}', textAlign: TextAlign.center),
                      selected: sel,
                      onSelected: (_) => setState(() => _category = e),
                      selectedColor: e.color.withValues(alpha: 0.22),
                      checkmarkColor: e.color,
                      showCheckmark: false,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                      side: BorderSide(color: sel ? e.color : AppColors.border, width: sel ? 2 : 1),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Aperçu temps réel',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLivePreview(),
          const SizedBox(height: AppSpacing.xxl),
          _buildPrimaryButton(),
          if (widget.mode == AgencyFormMode.edit) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              ),
              child: Text(
                'Annuler',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
