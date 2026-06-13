import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/admin_repository.dart';
import '../data/reports_management.dart';
import '../../feed/providers/feed_providers.dart';
import 'admin_drawer.dart';

class ReportsManagementScreen extends ConsumerStatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  ConsumerState<ReportsManagementScreen> createState() =>
      _ReportsManagementScreenState();
}

class _ReportsManagementScreenState
    extends ConsumerState<ReportsManagementScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final data = await repo.getPendingReports();
      setState(() {
        _reports = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _dismiss(String reportId) async {
    try {
      final repo = ref.read(reportsManagementRepositoryProvider);
      await repo.dismissReport(reportId);
      await _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement ignoré.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resolveAndDelete(String reportId, String articleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article ?'),
        content: const Text(
            'L\'article sera désactivé et le signalement marqué comme résolu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      await adminRepo.deactivateArticle(articleId);

      final repo = ref.read(reportsManagementRepositoryProvider);
      await repo.resolveReport(reportId);

      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article supprimé et signalement résolu.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        title: const Text('Signalements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : _reports.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 64),
                          SizedBox(height: 16),
                          Text('Aucun signalement en attente',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Signalement #${report['id'].toString().substring(0, 8)}',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      report['created_at']
                                          .toString()
                                          .split('T')[0],
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Divider(),

                                // Article
                                const Text('Article:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text(
                                    report['articles']?['title'] ??
                                        'Titre inconnu',
                                    style:
                                        const TextStyle(color: Colors.black)),
                                const SizedBox(height: 8),

                                // Raison
                                const Text('Raison:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text(report['reason'] ?? 'Non spécifiée',
                                    style:
                                        const TextStyle(color: Colors.black)),
                                const SizedBox(height: 8),

                                // Voir l'article
                                if (report['articles']?['content'] != null) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Contenu :',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      report['articles']['content'],
                                      style: const TextStyle(
                                          color: Colors.black87),
                                      maxLines: 8,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],

                                // Boutons
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _dismiss(report['id'] as String),
                                      child: const Text('Ignorer'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _resolveAndDelete(
                                        report['id'] as String,
                                        report['article_id'] as String,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Supprimer l\'article',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
