import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gap/gap.dart';

import '../../../shared/theme/app_theme.dart';
import '../../reactions/ui/emoji_panel.dart';
import '../../reports/ui/report_bottom_sheet.dart';

class ArticleWebViewScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final String? articleId;

  const ArticleWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.articleId,
  });

  @override
  ConsumerState<ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends ConsumerState<ArticleWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Text(
              widget.title,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              Uri.parse(widget.url).host,
              style: AppTextStyles.meta,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share('${widget.title}\n\n${widget.url}'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
      bottomNavigationBar: widget.articleId != null 
          ? _ReadingToolbar(articleId: widget.articleId!) 
          : null,
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Actualiser'),
              onTap: () {
                _controller.reload();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Ouvrir dans le navigateur'),
              onTap: () {
                // Launch URL in browser logic
                Navigator.pop(context);
              },
            ),
            if (widget.articleId != null)
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                title: const Text('Signaler l\'article', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  ReportBottomSheet.show(context, widget.articleId!);
                },
              ),
            const Gap(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ReadingToolbar extends StatelessWidget {
  final String articleId;

  const _ReadingToolbar({required this.articleId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bottomNav,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
        top: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => EmojiPanel.show(context, articleId),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.chipRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_reaction_outlined, size: 20, color: AppColors.primary),
                    const Gap(8),
                    Text(
                      'Réagir...',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          IconButton(
            onPressed: () => ReportBottomSheet.show(context, articleId),
            icon: const Icon(Icons.flag_outlined, color: AppColors.textTertiary),
            tooltip: 'Signaler',
          ),
        ],
      ),
    );
  }
}
