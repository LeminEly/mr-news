import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:mauritanie_news/shared/theme/app_theme.dart';

class ArticleWebViewScreen extends StatefulWidget {
  const ArticleWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<ArticleWebViewScreen> createState() => _ArticleWebViewScreenState();
}

class _ArticleWebViewScreenState extends State<ArticleWebViewScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;
  String? _errorMessage;

  String get _safeTitle {
    final t = widget.title.trim();
    if (t.length <= 40) return t;
    return '${t.substring(0, 37)}…';
  }

  Uri? get _uri {
    final u = widget.url.trim();
    final parsed = Uri.tryParse(u);
    if (parsed == null) return null;
    if (!parsed.hasScheme) return null;
    if (parsed.scheme != 'https' && parsed.scheme != 'http') return null;
    return parsed;
  }

  /// ORB et erreurs « sous-ressource » : le document peut quand même être affiché
  /// (cf. logs : `onPageFinished` après `ERR_BLOCKED_BY_ORB`).
  static bool _isIgnorableWebResourceError(WebResourceError error) {
    final d = error.description;
    if (d.contains('ERR_BLOCKED_BY_ORB')) return true;
    if (error.isForMainFrame == false) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    final uri = _uri;
    if (uri == null) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'URL invalide';
      return;
    }
    _initWebView(uri);
  }

  void _initWebView(Uri uri) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            debugPrint('WebView loading: $url');
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            debugPrint('WebView finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            debugPrint('WebView error code: ${error.errorCode}');
            debugPrint('WebView error type: ${error.errorType}');
            debugPrint('WebView error mainFrame: ${error.isForMainFrame}');
            if (_isIgnorableWebResourceError(error)) {
              return;
            }
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/112.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(
        uri,
        headers: const {
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.9,ar;q=0.8,en;q=0.7',
        },
      );
  }

  Future<void> _openInExternalBrowser() async {
    final uri = _uri ?? Uri.tryParse(widget.url.trim());
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Lien invalide',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Aucune application pour ouvrir ce lien.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Impossible d’ouvrir le navigateur : $e',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
          ),
        ),
      );
    }
  }

  Future<void> _retryLoad() async {
    final c = _webViewController;
    if (c == null) return;
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _errorMessage = null;
    });
    await c.reload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _webViewController;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: Text(
          _safeTitle,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textOnPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: controller == null
                ? null
                : () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    controller.reload();
                  },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: AppColors.textOnPrimary),
            tooltip: 'Ouvrir dans le navigateur',
            onPressed: _openInExternalBrowser,
          ),
        ],
      ),
      body: controller == null
          ? Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: _buildErrorBody(showRetry: false),
              ),
            )
          : Stack(
              children: [
                Visibility(
                  visible: !_hasError,
                  child: WebViewWidget(controller: controller),
                ),
                if (_isLoading && !_hasError)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                      backgroundColor: AppColors.primarySurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                if (_hasError)
                  ColoredBox(
                    color: AppColors.background,
                    child: Center(
                      child: Padding(
                        padding: AppSpacing.pagePadding,
                        child: _buildErrorBody(showRetry: true),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildErrorBody({required bool showRetry}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.link_off, size: 72, color: AppColors.error),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Impossible d’ouvrir cet article',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage ?? 'Erreur inconnue',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        if (showRetry) ...[
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              ),
              icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
              label: Text(
                'Réessayer',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.textOnPrimary),
              ),
              onPressed: _retryLoad,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              ),
              icon: const Icon(Icons.open_in_browser, color: AppColors.primary),
              label: Text(
                'Ouvrir dans le navigateur',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.primary),
              ),
              onPressed: _openInExternalBrowser,
            ),
          ),
        ],
      ],
    );
  }
}
