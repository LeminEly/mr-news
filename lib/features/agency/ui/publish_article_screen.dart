import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mauritanie_news/features/agency/data/agency_auth_service.dart';
import 'package:mauritanie_news/shared/theme/app_theme.dart';

import 'package:mauritanie_news/features/agency/ui/agency_article_form.dart';
import 'package:mauritanie_news/features/feed/providers/feed_providers.dart';
import 'package:mauritanie_news/shared/models/agency_model.dart';
import 'package:mauritanie_news/shared/models/article_model.dart';
import 'package:mauritanie_news/shared/models/category_model.dart';

/// Route `/agency/publish` : charge le profil agence courant puis affiche l’écran.
class AgencyPublishGate extends StatefulWidget {
  const AgencyPublishGate({super.key});

  @override
  State<AgencyPublishGate> createState() => _AgencyPublishGateState();
}

class _AgencyPublishGateState extends State<AgencyPublishGate> {
  AgencyModel? _agency;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadAgency);
  }

  Future<void> _loadAgency() async {
    try {
      final agency =
          await AgencyAuthService(Supabase.instance.client).getCurrentAgency();
      if (!mounted) return;
      setState(() {
        _agency = agency;
        _loading = false;
        _error = agency == null ? 'Profil agence introuvable' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_error != null || _agency == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Text(
              _error ?? 'Profil agence introuvable',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      );
    }
    return PublishArticleScreen(agency: _agency!);
  }
}

/// Écran publication d’article (Supabase).
class PublishArticleScreen extends ConsumerStatefulWidget {
  const PublishArticleScreen({super.key, required this.agency});

  final AgencyModel agency;

  @override
  ConsumerState<PublishArticleScreen> createState() => _PublishArticleScreenState();
}

class _PublishArticleScreenState extends ConsumerState<PublishArticleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientCtrl;
  late final ValueNotifier<String?> _coverImageUrlNotifier;
  bool _loading = true;
  List<CategoryModel> _categories = const [];
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _coverImageUrlNotifier = ValueNotifier<String?>(null);
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    Future<void>.microtask(_loadCategories);
  }

  @override
  void dispose() {
    _coverImageUrlNotifier.dispose();
    _gradientCtrl.dispose();
    super.dispose();
  }

  String _normalizedCoverExt(String path) {
    var e = path.split('.').last.toLowerCase();
    if (e.isEmpty || e.length > 8) return 'jpg';
    e = e.replaceFirst(RegExp(r'^\.'), '');
    return e;
  }

  String _contentTypeForCoverExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'La galerie n’est pas disponible sur le web.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      _isUploadingImage = true;
      _coverImageUrlNotifier.value = null;
    });

    try {
      final fileExt = _normalizedCoverExt(picked.path);
      final fileName =
          '${widget.agency.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final bytes = await picked.readAsBytes();

      await Supabase.instance.client.storage.from('article-covers').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeForCoverExt(fileExt),
              upsert: false,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('article-covers')
          .getPublicUrl(fileName);

      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _coverImageUrlNotifier.value = publicUrl;
      debugPrint('Image uploadée: $publicUrl');
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur upload image: $e',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.bottomSheet,
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(
                'Depuis la galerie',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                Future<void>.microtask(_pickImageFromGallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: Text(
                'Depuis une URL',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showUrlDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final urlController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        title: Text(
          'URL de l’image',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: urlController,
          decoration: InputDecoration(
            hintText: 'https://example.com/image.jpg',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              WidgetsBinding.instance.addPostFrameCallback((_) => urlController.dispose());
            },
            child: Text(
              'Annuler',
              style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            onPressed: () {
              final t = urlController.text.trim();
              if (t.startsWith('https://')) {
                _coverImageUrlNotifier.value = t;
                Navigator.pop(dialogCtx);
                WidgetsBinding.instance.addPostFrameCallback((_) => urlController.dispose());
              }
            },
            child: Text(
              'Confirmer',
              style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isUploadingImage) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.imageRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Upload en cours…',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final url = _coverImageUrlNotifier.value?.trim() ?? '';
    if (url.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.imageRadius,
            child: CachedNetworkImage(
              imageUrl: url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 180,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: GestureDetector(
              onTap: () => _coverImageUrlNotifier.value = null,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: AppColors.textOnPrimary, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.imageRadius,
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ajouter une image de couverture',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Galerie ou URL',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      if (!mounted) return;
      setState(() {
        _categories = (response as List)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
      debugPrint('Catégories chargées: ${_categories.length}');
      for (final c in _categories) {
        debugPrint('  - ${c.id} : ${c.nameFr}');
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Erreur de chargement des catégories',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _gradientCtrl,
          builder: (context, _) {
            final t = CurvedAnimation(parent: _gradientCtrl, curve: Curves.easeInOut).value;
            return AppBar(
              iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppColors.primary, AppColors.secondary, t)!,
                      Color.lerp(AppColors.secondary, AppColors.primary, t)!,
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Publier un article',
                style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textOnPrimary),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Image de couverture',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ValueListenableBuilder<String?>(
                      valueListenable: _coverImageUrlNotifier,
                      builder: (_, __, ___) => _buildImagePreview(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AgencyArticleForm(
                  mode: AgencyFormMode.publish,
                  categories: _categories,
                  hideCoverSection: true,
                  parentCoverUrlNotifier: _coverImageUrlNotifier,
                  onSubmit: ({
                    required String title,
                    required String sourceUrl,
                    String? coverImageUrl,
                    required String categoryId,
                    required ArticleLanguage language,
                  }) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    if (widget.agency.id.isEmpty) {
                      if (!mounted) return false;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            'Profil agence introuvable',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                        ),
                      );
                      return false;
                    }

                    if (widget.agency.status != AgencyStatus.approved) {
                      if (!mounted) return false;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.warning,
                          content: Text(
                            'Votre agence est en attente de validation. Vous pourrez publier après approbation.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                          duration: const Duration(seconds: 6),
                        ),
                      );
                      return false;
                    }

                    if (categoryId.isEmpty) {
                      if (!mounted) return false;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            'Sélectionnez une catégorie',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                        ),
                      );
                      return false;
                    }

                    if (title.trim().isEmpty || sourceUrl.trim().isEmpty) {
                      if (!mounted) return false;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            'Titre et lien source sont obligatoires',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                        ),
                      );
                      return false;
                    }

                    try {
                      await ref.read(agencyRepositoryProvider).publishArticle(
                            agencyId: widget.agency.id,
                            title: title.trim(),
                            sourceUrl: sourceUrl.trim(),
                            coverImageUrl: coverImageUrl,
                            categoryId: categoryId,
                            language: language,
                          );
                      if (!mounted) return true;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.success,
                          content: Text(
                            'Article publié avec succès !',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textOnPrimary),
                          ),
                        ),
                      );
                      navigator.pop(true);
                      return true;
                    } catch (e) {
                      String errorMessage;
                      if (e is PostgrestException) {
                        errorMessage =
                            'BD: ${e.message} | code: ${e.code} | hint: ${e.hint}';
                        debugPrint('=== SUPABASE ERROR ===');
                        debugPrint('message: ${e.message}');
                        debugPrint('code: ${e.code}');
                        debugPrint('details: ${e.details}');
                        debugPrint('hint: ${e.hint}');
                      } else {
                        errorMessage = e.toString();
                        debugPrint('=== DART ERROR === $e');
                      }
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              errorMessage,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textOnPrimary),
                            ),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 8),
                          ),
                        );
                      }
                      return false;
                    }
                  },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
