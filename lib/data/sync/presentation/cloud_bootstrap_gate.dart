import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../cloud_bootstrap_cubit.dart';
import '../cloud_bootstrap_state.dart';
import 'cloud_bootstrap_choice_page.dart';
import 'cloud_bootstrap_progress_page.dart';

/// Gate widget that sits between SubscriptionGate and InventoryShellPage.
/// Handles the cloud bootstrap flow for fresh devices.
class CloudBootstrapGate extends StatelessWidget {
  const CloudBootstrapGate({
    super.key,
    required this.tenantId,
    required this.child,
    required this.cloudBootstrapCubit,
  });

  final String tenantId;
  final Widget child;
  final CloudBootstrapCubit cloudBootstrapCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CloudBootstrapCubit>.value(
      value: cloudBootstrapCubit,
      child: BlocBuilder<CloudBootstrapCubit, CloudBootstrapState>(
        builder: (context, state) {
          // Ready states → pass through to child
          if (state is CloudBootstrapLocalReady) {
            return child;
          }
          if (state is CloudBootstrapSuccess) {
            // Briefly show success then pass through
            return _SuccessTransition(
              importedRows: state.importedRows,
              child: child,
            );
          }

          // Checking / initial
          if (state is CloudBootstrapInitial ||
              state is CloudBootstrapChecking) {
            return const CloudBootstrapProgressPage(
              message: 'Préparation de vos données…',
            );
          }

          // Pulling
          if (state is CloudBootstrapPulling) {
            return CloudBootstrapProgressPage(message: state.message);
          }

          // User needs to choose
          if (state is CloudBootstrapNeedsChoice) {
            return CloudBootstrapChoicePage(
              localStatus: state.localStatus,
              pendingOutboxCount: state.pendingOutboxCount,
              onContinueLocal: () =>
                  context.read<CloudBootstrapCubit>().continueLocal(),
              onPullFromCloud: () =>
                  context.read<CloudBootstrapCubit>().pullFromCloud(),
            );
          }

          // Failure
          if (state is CloudBootstrapFailure) {
            return _FailurePage(
              message: state.message,
              hasLocalData: state.hasLocalData,
              onRetry: () => context.read<CloudBootstrapCubit>().retry(),
              onContinueLocal: state.hasLocalData
                  ? () => context.read<CloudBootstrapCubit>().continueLocal()
                  : null,
            );
          }

          return child;
        },
      ),
    );
  }
}

class _SuccessTransition extends StatefulWidget {
  const _SuccessTransition({required this.importedRows, required this.child});

  final int importedRows;
  final Widget child;

  @override
  State<_SuccessTransition> createState() => _SuccessTransitionState();
}

class _SuccessTransitionState extends State<_SuccessTransition> {
  bool _showChild = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showChild = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) return widget.child;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Données importées avec succès !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.importedRows} éléments téléchargés.',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailurePage extends StatelessWidget {
  const _FailurePage({
    required this.message,
    required this.hasLocalData,
    required this.onRetry,
    this.onContinueLocal,
  });

  final String message;
  final bool hasLocalData;
  final VoidCallback onRetry;
  final VoidCallback? onContinueLocal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppColors.danger, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Impossible de télécharger les données cloud',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Vérifiez votre connexion internet.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 44),
                ),
                onPressed: onRetry,
              ),
              if (onContinueLocal != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.storage),
                  label: const Text('Continuer en mode local'),
                  onPressed: onContinueLocal,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
