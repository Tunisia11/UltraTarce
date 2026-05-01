import '../../domain/app_models.dart';
import '../../core/result/app_result.dart';
import '../../storage/app_snapshot_codec.dart';
import 'app_repository.dart';

class BackupImportPreview {
  const BackupImportPreview(this.snapshot);

  final AppSnapshot snapshot;

  int get productCount => snapshot.products.length;
  int get documentCount => snapshot.documents.length;
  int get auditEventCount => snapshot.auditEvents.length;
}

class BackupRepository {
  BackupRepository(this._appRepository);

  final AppRepository _appRepository;

  String exportBackup() {
    return AppSnapshotCodec.encodePortableBackup(_appRepository.snapshot);
  }

  BackupImportPreview importPreview(String raw) {
    return BackupImportPreview(AppSnapshotCodec.decodeTrustedSnapshot(raw));
  }

  AppSnapshot confirmRestore(
    BackupImportPreview preview, {
    required String status,
  }) {
    _appRepository.replace(preview.snapshot, status: status);
    return preview.snapshot;
  }

  Future<AppResult<void>> flushPendingWritesResult() {
    return _appRepository.flushPendingMutationResult();
  }
}
