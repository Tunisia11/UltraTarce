import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/result/app_result.dart';
import 'remote_pull_repository.dart';
import 'sync_metadata_repository.dart';
import 'local_cloud_import_service.dart';

class IncrementalPullResult {
  const IncrementalPullResult({
    required this.totalRows,
    required this.conflictCount,
    this.lastPullAt,
  });

  final int totalRows;
  final int conflictCount;
  final DateTime? lastPullAt;

  bool get hasConflicts => conflictCount > 0;
}

class SyncPullService {
  SyncPullService({
    required RemotePullRepository remotePullRepository,
    required SyncMetadataRepository metadataRepository,
    required LocalCloudImportService importService,
  }) : _remotePullRepository = remotePullRepository,
       _metadataRepository = metadataRepository,
       _importService = importService;

  final RemotePullRepository _remotePullRepository;
  final SyncMetadataRepository _metadataRepository;
  final LocalCloudImportService _importService;

  Future<AppResult<IncrementalPullResult>> pullIncremental({
    required String tenantId,
    required String deviceId,
  }) async {
    try {
      final lastPull = await _metadataRepository.getLastPullCompletedAt(
        tenantId,
      );
      debugPrint(
        '[sync] Starting incremental pull for $tenantId since $lastPull',
      );

      final pullResult = await _remotePullRepository.pullTenantData(
        tenantId,
        since: lastPull,
      );

      if (pullResult.isEmpty) {
        debugPrint('[sync] No new changes in cloud.');
        return AppSuccess(
          IncrementalPullResult(
            totalRows: 0,
            conflictCount: 0,
            lastPullAt: lastPull,
          ),
        );
      }

      debugPrint(
        '[sync] Fetched ${pullResult.totalRows} changed rows from cloud.',
      );

      // Import logic with conflict detection
      final result = await _importService.importIncremental(
        tenantId: tenantId,
        pullResult: pullResult,
      );

      if (pullResult.pulledAt != null) {
        await _metadataRepository.setLastPullCompletedAt(
          tenantId,
          pullResult.pulledAt!,
        );
      }

      return AppSuccess(
        IncrementalPullResult(
          totalRows: pullResult.totalRows,
          conflictCount: result.conflictCount,
          lastPullAt: pullResult.pulledAt,
        ),
      );
    } catch (e, stack) {
      debugPrint('[sync] Incremental pull failed: $e\n$stack');
      return AppFailure(
        AppError(
          code: 'pull_failed',
          message: 'Impossible de télécharger les changements cloud.',
          cause: e,
        ),
      );
    }
  }
}
