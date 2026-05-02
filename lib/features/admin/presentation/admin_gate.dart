import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_colors.dart';
import '../data/admin_repository.dart';
import '../application/admin_dashboard_cubit.dart';
import 'admin_dashboard_page.dart';
import 'admin_tenants_page.dart';
import 'admin_sync_health_page.dart';
import 'admin_subscriptions_page.dart';
import '../data/admin_subscription_repository.dart';
import '../application/admin_subscription_cubit.dart';
import '../data/admin_trial_request_repository.dart';
import '../application/admin_trial_requests_cubit.dart';
import 'admin_trial_requests_page.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key, this.repository, this.subscriptionRepository});

  final AdminRepository? repository;
  final AdminSubscriptionRepository? subscriptionRepository;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final AdminRepository _repository;
  late final AdminSubscriptionRepository _subscriptionRepository;
  late final AdminTrialRequestRepository? _trialRequestRepository;
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    final supabaseClient = _maybeSupabaseClient();
    _repository = widget.repository ?? AdminRepository(supabaseClient!);
    _subscriptionRepository =
        widget.subscriptionRepository ??
        AdminSubscriptionRepository(supabaseClient!);
    _trialRequestRepository = supabaseClient == null
        ? null
        : AdminTrialRequestRepository(supabaseClient);
    _checkAdmin();
  }

  SupabaseClient? _maybeSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _repository.checkIsPlatformAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin!) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceHighest,
          title: const Text('Administration Virex'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text(
                'Accès administrateur non autorisé.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour à l\'application'),
              ),
            ],
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AdminDashboardCubit(_repository)..loadDashboard(),
        ),
        BlocProvider(
          create: (_) => AdminSubscriptionCubit(_subscriptionRepository),
        ),
        BlocProvider(
          create: (_) =>
              AdminTrialRequestsCubit(_trialRequestRepository)..loadRequests(),
        ),
      ],
      child: const AdminShell(),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceHighest,
        title: const Text(
          'Administration Virex',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AdminDashboardCubit>().refresh(),
          ),
          TextButton.icon(
            icon: const Icon(Icons.exit_to_app, color: AppColors.danger),
            label: const Text(
              'Retour à l\'app',
              style: TextStyle(color: AppColors.danger),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surfaceLow,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Vue générale'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business),
                label: Text('Clients / Sociétés'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.health_and_safety_outlined),
                selectedIcon: Icon(Icons.health_and_safety),
                label: Text('Santé sync'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.subscriptions_outlined),
                selectedIcon: Icon(Icons.subscriptions),
                label: Text('Abonnements'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_ind_outlined),
                selectedIcon: Icon(Icons.assignment_ind),
                label: Text('Demandes d\'essai'),
              ),
            ],
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                AdminDashboardPage(),
                AdminTenantsPage(),
                AdminSyncHealthPage(),
                AdminSubscriptionsPage(),
                AdminTrialRequestsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
