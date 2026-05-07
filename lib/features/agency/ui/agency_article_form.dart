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

import 'package:mauritanie_news/shared/models/article_model.dart';
import 'package:mauritanie_news/shared/models/category_model.dart';

/// Mode du formulaire agence (publication ou édition).
enum AgencyFormMode { publish, edit }

typedef AgencyArticleSubmit = Future<bool> Function({
  required String title,
  required String sourceUrl,
  String? coverImageUrl,
  required String categoryId,
  required ArticleLanguage language,
});

/// Envoie une image choisie sur l’appareil vers le Storage ; retourne l’URL publique.
typedef UploadPickedCover = Future<String> Function(XFile file);

/// Formulaire article — partagé publication / édition.
class AgencyArticleForm extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables — [parentCoverUrlNotifier] empêche const.
  AgencyArticleForm({
    super.key,
    required this.mode,
    required this.categories,
    this.initial,
    required this.onSubmit,
    this.onCancel,
    this.hideCoverSection = false,
    this.parentCoverUrlNotifier,
    this.uploadPickedCover,
  });

  final AgencyFormMode mode;
  final List<CategoryModel> categories;
  final ArticleModel? initial;
  final AgencyArticleSubmit onSubmit;
  final VoidCallback? onCancel;

  /// Si vrai, la zone image / galerie / URL est gérée par l’écran parent (ex. upload Storage).
  final bool hideCoverSection;

  /// URL publique de couverture (parent) ; lu à la soumission et pour l’aperçu.
  final ValueNotifier<String?>? parentCoverUrlNotifier;

  /// Requis pour enregistrer une image prise depuis la galerie (hors mode parent URL).
  final UploadPickedCover? uploadPickedCover;

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
  ArticleLanguage _language = ArticleLanguage.fr;
  String? _categoryId;

  bool _loading = false;
  bool _success = false;

  late final AnimationController _checkCtrl;

  CategoryModel? get _selectedCategory {
    final id = _categoryId;
    if (id == null) return null;
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
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
      _categoryId = initial.categoryId;
    } else {
      _categoryId = widget.categories.isEmpty ? null : widget.categories.first.id;
    }

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    widget.parentCoverUrlNotifier?.addListener(_onParentCoverChanged);
  }

  void _onParentCoverChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.parentCoverUrlNotifier?.removeListener(_onParentCoverChanged);
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
    if (!_formKey.currentState!.validate()) return;
    final categoryId = _categoryId;
    if (categoryId == null) return;

    setState(() {
      _loading = true;
      _success = false;
    });

    final String? coverResolved;
    if (widget.hideCoverSection && widget.parentCoverUrlNotifier != null) {
      final v = widget.parentCoverUrlNotifier!.value?.trim();
      coverResolved = (v == null || v.isEmpty) ? null : v;
    } else if (!kIsWeb && _pickedFile != null) {
      final upload = widget.uploadPickedCover;
      if (upload == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Envoi de l’image depuis le téléphone n’est pas disponible.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
      try {
        coverResolved = await upload(_pickedFile!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Erreur envoi image : $e',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }
    } else {
      final net = _coverNetworkUrl?.trim();
      if (net != null && net.isNotEmpty) {
        coverResolved = net;
      } else {
        coverResolved = widget.initial?.coverImageUrl;
      }
    }

    final ok = await widget.onSubmit(
      title: _titleCtrl.text.trim(),
      sourceUrl: _urlCtrl.text.trim(),
      coverImageUrl: coverResolved,
      categoryId: categoryId,
      language: _language,
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      setState(() => _success = true);
      await _checkCtrl.forward(from: 0);
    }
  }

  Widget _buildCoverPreview({bool useHero = false}) {
    if (widget.hideCoverSection && widget.parentCoverUrlNotifier != null) {
      final coverUrlStr = widget.parentCoverUrlNotifier!.value?.trim() ?? '';
      if (coverUrlStr.isEmpty) {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: AppRadius.imageRadius,
            child: Container(
              color: AppColors.surfaceVariant,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 40),
            ),
          ),
        );
      }
      Widget imageChild = CachedNetworkImage(
        imageUrl: coverUrlStr,
        fit: BoxFit.cover,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surfaceVariant,
          highlightColor: AppColors.surface,
          child: Container(color: AppColors.surfaceVariant),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.surfaceVariant,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.textTertiary, size: 40),
        ),
      );
      if (useHero) {
        imageChild = Hero(
          tag: 'cover_image_$_heroId',
          child: imageChild,
        );
      }
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: AppRadius.imageRadius,
          child: imageChild,
        ),
      );
    }

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
    final cat = _selectedCategory;
    final dateStr = DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.now());
    final titleStyle = _language == ArticleLanguage.ar
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
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Text(
                cat == null
                    ? 'Catégorie'
                    : '${cat.icon} ${cat.name(Localizations.localeOf(context))}',

                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Directionality(
            textDirection: _language == ArticleLanguage.ar
                ? ui.TextDirection.rtl
                : ui.TextDirection.ltr,
            child: Text(
              _titleCtrl.text.trim().isEmpty ? 'Titre de l’article…' : _titleCtrl.text.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: titleStyle.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dateStr,
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
          if (!widget.hideCoverSection) ...[
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
          ],
          if (widget.hideCoverSection) const SizedBox(height: AppSpacing.sm),
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
            selected: {_language.name},
            emptySelectionAllowed: false,
            onSelectionChanged: (s) {
              setState(() => _language = ArticleLanguage.values
                  .firstWhere((e) => e.name == s.first));
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
                children: widget.categories.map((e) {
                  final sel = _categoryId == e.id;
                  return SizedBox(
                    width: w,
                    child: FilterChip(
                      label: Text(
                        '${e.icon} ${e.name(Localizations.localeOf(context))}',

                        textAlign: TextAlign.center,
                      ),
                      selected: sel,
                      onSelected: (_) => setState(() => _categoryId = e.id),
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      checkmarkColor: AppColors.primary,
                      showCheckmark: false,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: sel ? AppColors.primary : AppColors.border,
                        width: sel ? 2 : 1,
                      ),
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
