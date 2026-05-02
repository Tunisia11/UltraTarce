import 'package:flutter_bloc/flutter_bloc.dart';

import 'cloud_bootstrap_state.dart';
import 'local_cloud_import_service.dart';
import 'remote_pull_repository.dart';

/// Cubit that orchestrates the cloud bootstrap flow after tenant selection.
///
/// Decision tree:
/// 1. Check local data status.
/// 2. If empty → attempt cloud pull.
///    - If cloud has data → import automatically.
///    - If cloud is also empty → continue local.
///    - If network error → show failure with retry.
/// 3. If local has data → emit NeedsChoice (never auto-overwrite).
class CloudBootstrapCubit extends Cubit<CloudBootstrapState> {
  CloudBootstrapCubit({
    required this.remotePullRepository,
    required this.importService,
  }) : super(const CloudBootstrapInitial());

  CloudBootstrapCubit.localOnly()
    : remotePullRepository = null,
      importService = null,
      super(const CloudBootstrapLocalReady());

  final RemotePullRepository? remotePullRepository;
  final LocalCloudImportService? importService;

  String _tenantId = '';

  /// Start the bootstrap check for a given tenant.
  Future<void> checkBootstrap(String tenantId) async {
    _tenantId = tenantId;
    if (importService == null || remotePullRepository == null) {
      emit(const CloudBootstrapLocalReady());
      return;
    }

    emit(const CloudBootstrapChecking());

    try {
      final localStatus = await importService!.inspectLocal(tenantId);

      if (localStatus.isEmpty) {
        // Fresh device — try cloud pull
        await _attemptCloudPull(tenantId);
      } else {
        // Local data exists — ask user
        final pendingOutbox = await importService!.countPendingOutbox(tenantId);
        emit(
          CloudBootstrapNeedsChoice(
            localStatus: localStatus,
            pendingOutboxCount: pendingOutbox,
          ),
        );
      }
    } catch (e) {
      emit(
        CloudBootstrapFailure(
          message: 'Erreur lors de la vérification: $e',
          hasLocalData: false,
        ),
      );
    }
  }

  /// User chose to continue with local data.
  void continueLocal() {
    emit(const CloudBootstrapLocalReady());
  }

  /// User chose to pull from cloud (overwrite local).
  Future<void> pullFromCloud() async {
    if (importService == null || remotePullRepository == null) return;

    // Check for pending outbox first
    try {
      final pendingOutbox = await importService!.countPendingOutbox(_tenantId);
      if (pendingOutbox > 0) {
        emit(
          CloudBootstrapFailure(
            message:
                '$pendingOutbox modification(s) locale(s) en attente de synchronisation. '
                'Synchronisez d\'abord ou exportez une sauvegarde.',
            hasLocalData: true,
          ),
        );
        return;
      }
    } catch (_) {
      // If we can't check, proceed cautiously
    }

    await _attemptCloudPull(_tenantId);
  }

  /// Retry after a failure.
  Future<void> retry() async {
    await checkBootstrap(_tenantId);
  }

  Future<void> _attemptCloudPull(String tenantId) async {
    if (importService == null || remotePullRepository == null) return;

    emit(
      const CloudBootstrapPulling(message: 'Téléchargement des données cloud…'),
    );

    try {
      final pullResult = await remotePullRepository!.pullTenantData(tenantId);

      if (pullResult.isEmpty) {
        // Cloud is empty too — just continue
        emit(const CloudBootstrapLocalReady());
        return;
      }

      emit(
        const CloudBootstrapPulling(
          message:
              'Import des données en cours…\nProduits, clients, documents…',
        ),
      );

      final importedRows = await importService!.importRemoteData(
        tenantId: tenantId,
        pullResult: pullResult,
      );

      emit(CloudBootstrapSuccess(importedRows: importedRows));
    } catch (e) {
      final hasLocal = !(await importService!.inspectLocal(tenantId)).isEmpty;
      emit(
        CloudBootstrapFailure(
          message: 'Impossible de télécharger les données cloud.\n$e',
          hasLocalData: hasLocal,
        ),
      );
    }
  }
}
