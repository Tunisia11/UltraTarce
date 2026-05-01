import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/app_result.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';

class BackupState {
  const BackupState({
    this.exportJson,
    this.preview,
    this.restoredSnapshot,
    this.message,
    this.lastMutationResult,
  });

  final String? exportJson;
  final BackupImportPreview? preview;
  final AppSnapshot? restoredSnapshot;
  final String? message;
  final AppResult<AppSnapshot>? lastMutationResult;
}

class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._backupRepository, this._auditRepository)
    : super(const BackupState());

  final BackupRepository _backupRepository;
  final AuditRepository _auditRepository;

  String exportBackup() {
    final json = _backupRepository.exportBackup();
    emit(BackupState(exportJson: json));
    return json;
  }

  BackupImportPreview importBackupPreview(String raw) {
    final preview = _backupRepository.importPreview(raw);
    emit(BackupState(preview: preview));
    return preview;
  }

  AppSnapshot confirmRestore(BackupImportPreview preview) {
    _backupRepository.confirmRestore(preview, status: 'Base locale restaurée.');
    final snapshot = _auditRepository.saveAll(
      AuditService.append(
        events: _auditRepository.getAll(),
        action: 'Restauration',
        target: 'Base locale',
        detail: 'Données restaurées depuis un export JSON.',
      ),
      status: 'Base locale restaurée.',
    );
    emit(
      BackupState(
        preview: preview,
        restoredSnapshot: snapshot,
        message: 'Base locale restaurée.',
      ),
    );
    return snapshot;
  }

  Future<AppResult<AppSnapshot>> confirmRestoreResult(
    BackupImportPreview preview,
  ) async {
    try {
      final snapshot = confirmRestore(preview);
      final persistence = await _backupRepository.flushPendingWritesResult();
      if (persistence is AppFailure<void>) {
        final result = AppFailure<AppSnapshot>(persistence.error);
        emit(
          BackupState(
            preview: preview,
            restoredSnapshot: snapshot,
            message: persistence.error.message,
            lastMutationResult: result,
          ),
        );
        return result;
      }
      final result = AppSuccess(snapshot);
      emit(
        BackupState(
          preview: preview,
          restoredSnapshot: snapshot,
          message: 'Base locale restaurée.',
          lastMutationResult: result,
        ),
      );
      return result;
    } catch (error) {
      final result = AppFailure<AppSnapshot>(
        AppError(
          code: 'backup_restore_failed',
          message: 'Impossible de restaurer la sauvegarde.',
          cause: error,
        ),
      );
      emit(
        BackupState(
          preview: preview,
          message: result.error.message,
          lastMutationResult: result,
        ),
      );
      return result;
    }
  }

  Future<void> copyBackupJsonIfCurrentFeatureExists() async {
    final json = state.exportJson ?? exportBackup();
    await Clipboard.setData(ClipboardData(text: json));
    emit(BackupState(exportJson: json, message: 'Copie prête.'));
  }
}
