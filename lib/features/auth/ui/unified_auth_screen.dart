import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../shared/models/agency_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../app/router.dart';
import '../../agency/data/agency_auth_service.dart';
import '../../feed/providers/feed_providers.dart';

class UnifiedAuthScreen extends ConsumerStatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  ConsumerState<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends ConsumerState<UnifiedAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            // Header
            Column(
              children: [
                const Icon(Icons.newspaper, color: AppColors.primary, size: 64),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Mr-News Portal',
                  style: AppTextStyles.displayMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Accès Administration & Agences',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.buttonRadius,
                  ),
                  labelColor: AppColors.textOnPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Admin'),
                    Tab(text: 'Agence'),
                  ],
                ),
              ),
            ),
            
            // Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _AdminLoginView(),
                  _AgencyView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminLoginView extends ConsumerStatefulWidget {
  const _AdminLoginView();

  @override
  ConsumerState<_AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends ConsumerState<_AdminLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final role = response.user?.userMetadata?['role'] as String?;
      if (role != 'admin') {
        await supabase.auth.signOut();
        throw 'Accès réservé aux administrateurs';
      }

      if (!mounted) return;
      context.go(AppRoutes.adminDashboard);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Connexion Administrateur',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgencyView extends StatefulWidget {
  const _AgencyView();

  @override
  State<_AgencyView> createState() => _AgencyViewState();
}

class _AgencyViewState extends State<_AgencyView> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            _isLogin ? 'Espace Agence' : 'Inscription Agence',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          if (_isLogin)
            const _AgencyLoginSection()
          else
            const _AgencySignUpSection(),

          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(_isLogin ? "Pas de compte ? S'inscrire" : "Déjà un compte ? Se connecter"),
          ),
        ],
      ),
    );
  }
}

class _AgencyLoginSection extends ConsumerStatefulWidget {
  const _AgencyLoginSection();

  @override
  ConsumerState<_AgencyLoginSection> createState() => _AgencyLoginSectionState();
}

class _AgencyLoginSectionState extends ConsumerState<_AgencyLoginSection> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final authService = AgencyAuthService(supabase);
      final agency = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      
      if (agency?.status == AgencyStatus.approved) {
        context.go(AppRoutes.agencyDashboard);
      } else {
        context.go(AppRoutes.agencyPending);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: _isLoading ? const CircularProgressIndicator() : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

class _AgencySignUpSection extends ConsumerStatefulWidget {
  const _AgencySignUpSection();

  @override
  ConsumerState<_AgencySignUpSection> createState() => _AgencySignUpSectionState();
}

class _AgencySignUpSectionState extends ConsumerState<_AgencySignUpSection> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final authService = AgencyAuthService(supabase);
      await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        agencyName: _nameController.text.trim(),
        websiteUrl: '',
        mediaType: 'other',
      );

      if (!mounted) return;
      context.go(AppRoutes.agencyPending);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nom de l'agence", prefixIcon: Icon(Icons.business_outlined)),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: _isLoading ? const CircularProgressIndicator() : const Text("S'inscrire"),
          ),
        ],
      ),
    );
  }
}
