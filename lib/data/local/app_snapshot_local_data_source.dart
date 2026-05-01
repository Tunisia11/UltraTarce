import '../../app/app_assets.dart';
import '../../domain/app_models.dart';
import '../../domain/services/sequence_service.dart';
import '../../storage/app_snapshot_codec.dart';
import '../../storage/app_storage.dart';
import '../../storage/app_storage_keys.dart';

class AppSnapshotLoadResult {
  const AppSnapshotLoadResult({
    required this.snapshot,
    required this.status,
    required this.loadedFromStorage,
    required this.recoveredFromFallback,
    this.savedAt,
  });

  final AppSnapshot snapshot;
  final String status;
  final bool loadedFromStorage;
  final bool recoveredFromFallback;
  final DateTime? savedAt;
}

class AppSnapshotLocalDataSource {
  AppSnapshotLocalDataSource({AppSnapshot? fallbackSnapshot})
    : _fallbackSnapshot = fallbackSnapshot ?? defaultSnapshot();

  final AppSnapshot _fallbackSnapshot;

  AppSnapshot get fallbackSnapshot => _reconciled(_fallbackSnapshot);

  AppSnapshotLoadResult load() {
    final candidates = [
      ...readPersistentValueCandidates(appStateStorageKey),
      ...readPersistentValueCandidates(legacyAppStateStorageKey),
    ];

    if (candidates.isEmpty) {
      final snapshot = _reconciled(_fallbackSnapshot);
      save(snapshot);
      return AppSnapshotLoadResult(
        snapshot: snapshot,
        status: 'Données initiales sauvegardées localement.',
        loadedFromStorage: false,
        recoveredFromFallback: false,
        savedAt: DateTime.now(),
      );
    }

    AppSnapshot? snapshot;
    var recoveredFromFallback = false;
    for (var index = 0; index < candidates.length; index++) {
      try {
        final candidate = AppSnapshotCodec.decodeTrustedSnapshot(
          candidates[index],
        );
        if (candidate.warehouses.isEmpty) {
          throw const FormatException('Snapshot incomplet');
        }
        snapshot = candidate;
        recoveredFromFallback = index > 0;
        break;
      } catch (_) {
        continue;
      }
    }

    if (snapshot == null) {
      return AppSnapshotLoadResult(
        snapshot: _reconciled(_fallbackSnapshot),
        status:
            'Sauvegarde locale illisible; aucune donnée existante n’a été écrasée.',
        loadedFromStorage: false,
        recoveredFromFallback: false,
      );
    }

    final safeSnapshot = _reconciled(snapshot);
    if (recoveredFromFallback) {
      save(safeSnapshot);
    }
    return AppSnapshotLoadResult(
      snapshot: safeSnapshot,
      status: recoveredFromFallback
          ? 'Données restaurées depuis une copie de secours locale.'
          : 'Données restaurées depuis ${persistentStoreLabel()}.',
      loadedFromStorage: true,
      recoveredFromFallback: recoveredFromFallback,
      savedAt: DateTime.now(),
    );
  }

  void save(AppSnapshot snapshot) {
    writePersistentValue(
      appStateStorageKey,
      AppSnapshotCodec.encodePortableBackup(_reconciled(snapshot)),
    );
  }

  AppSnapshot update(
    AppSnapshot snapshot,
    AppSnapshot Function(AppSnapshot) fn,
  ) {
    final updated = _reconciled(fn(snapshot));
    save(updated);
    return updated;
  }

  static AppSnapshot defaultSnapshot() {
    return AppSnapshot(
      company: const CompanyProfile(
        name: 'Nouveau magasin',
        taxId: '',
        address: '',
        city: '',
        phone: '',
        email: '',
        logoSource: AppAssets.systemLogoSource,
        invoiceFooter: 'Merci pour votre confiance.',
        timbreFiscalEnabled: true,
        timbreFiscalAmount: 1,
      ),
      warehouses: const [
        Warehouse(id: 'main', name: 'Dépôt principal', city: '', code: 'MAIN'),
      ],
      categories: const [Category(id: 'cat-default', name: 'Électronique')],
      products: const [],
      partners: const [],
      documents: const [],
      movements: const [],
      sequences: const {},
      auditEvents: const [],
    );
  }

  AppSnapshot _reconciled(AppSnapshot snapshot) {
    return AppSnapshot(
      company: AppSnapshotCodec.safeCompanyProfile(snapshot.company),
      warehouses: snapshot.warehouses,
      categories: snapshot.categories,
      products: snapshot.products,
      partners: snapshot.partners,
      documents: snapshot.documents,
      movements: snapshot.movements,
      sequences: SequenceService.reconcile(
        sequences: snapshot.sequences.isEmpty
            ? SequenceService.initialSequences()
            : snapshot.sequences,
        documents: snapshot.documents,
      ),
      auditEvents: snapshot.auditEvents,
    );
  }
}
