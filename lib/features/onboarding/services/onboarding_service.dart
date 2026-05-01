import 'dart:convert';

import '../../../app/app_assets.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../storage/app_snapshot_codec.dart';
import '../../../storage/app_storage.dart';
import '../../../storage/app_storage_keys.dart';
import '../models/store_setup_data.dart';

class OnboardingLaunchState {
  const OnboardingLaunchState({
    required this.shouldShowOnboarding,
    required this.initialSetup,
  });

  final bool shouldShowOnboarding;
  final StoreSetupData initialSetup;
}

/// Safe onboarding coordinator for launch decisions and setup persistence.
///
/// Phase 1 keeps the current local snapshot architecture, but moves the
/// decision-making and merge logic out of the launch widget so onboarding can
/// never wipe an existing business database again.
class OnboardingService {
  const OnboardingService();

  OnboardingLaunchState loadLaunchState({
    bool showOnboardingEveryLaunch = false,
  }) {
    final snapshot = _readSnapshot();
    final savedSetup = loadDraft() ?? StoreSetupData.empty();
    final initialSetup = _prefillSetup(savedSetup, snapshot);

    if (showOnboardingEveryLaunch) {
      return OnboardingLaunchState(
        shouldShowOnboarding: true,
        initialSetup: initialSetup,
      );
    }

    return OnboardingLaunchState(
      shouldShowOnboarding: _shouldRunOnboarding(snapshot),
      initialSetup: initialSetup,
    );
  }

  StoreSetupData? loadDraft() {
    final raw = readPersistentValue(onboardingStoreSetupStorageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return StoreSetupData.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  void saveDraft(StoreSetupData setup) {
    writePersistentValue(
      onboardingStoreSetupStorageKey,
      jsonEncode(setup.toJson()),
    );
  }

  void completeSetup(StoreSetupData setup) {
    final existing = _readSnapshot();
    final snapshot = existing == null
        ? setup.toCleanSnapshot()
        : _mergeSetupIntoSnapshot(existing, setup);

    writePersistentValue(
      appStateStorageKey,
      AppSnapshotCodec.encodePortableBackup(snapshot),
    );
    deletePersistentValue(legacyAppStateStorageKey);
    saveDraft(setup);
    writePersistentValue(onboardingCompletedStorageKey, 'true');
  }

  bool _shouldRunOnboarding(AppSnapshot? snapshot) {
    if (snapshot == null) return true;

    final completed =
        readPersistentValue(onboardingCompletedStorageKey) == 'true';
    if (_hasOperationalData(snapshot)) {
      return false;
    }

    if (!completed) {
      return true;
    }

    return !_hasCompanyIdentity(snapshot.company) ||
        snapshot.warehouses.isEmpty;
  }

  bool _hasOperationalData(AppSnapshot snapshot) {
    return snapshot.products.isNotEmpty ||
        snapshot.partners.isNotEmpty ||
        snapshot.documents.isNotEmpty ||
        snapshot.movements.isNotEmpty ||
        snapshot.auditEvents.isNotEmpty;
  }

  bool _hasCompanyIdentity(CompanyProfile company) {
    return company.name.trim().isNotEmpty &&
        !_isPlaceholderCompanyName(company.name) &&
        company.taxId.trim().isNotEmpty &&
        company.address.trim().isNotEmpty &&
        company.city.trim().isNotEmpty &&
        company.phone.trim().isNotEmpty &&
        company.email.trim().isNotEmpty;
  }

  bool _isPlaceholderCompanyName(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'nouveau magasin';
  }

  StoreSetupData _prefillSetup(StoreSetupData draft, AppSnapshot? snapshot) {
    if (snapshot == null) return draft;

    final company = snapshot.company;
    final warehouse = snapshot.warehouses.isEmpty
        ? null
        : snapshot.warehouses.first;
    return draft.copyWith(
      storeName: draft.storeName.trim().isEmpty ? company.name : null,
      taxId: draft.taxId.trim().isEmpty ? company.taxId : null,
      address: draft.address.trim().isEmpty ? company.address : null,
      city: draft.city.trim().isEmpty ? company.city : null,
      phone: draft.phone.trim().isEmpty ? company.phone : null,
      email: draft.email.trim().isEmpty ? company.email : null,
      depotName: draft.depotName.trim().isEmpty ? warehouse?.name ?? '' : null,
      depotCode: draft.depotCode.trim().isEmpty ? warehouse?.code ?? '' : null,
      depotCity: draft.depotCity.trim().isEmpty ? warehouse?.city ?? '' : null,
      depotAddress: draft.depotAddress.trim().isEmpty
          ? warehouse?.address ?? ''
          : null,
    );
  }

  AppSnapshot? _readSnapshot() {
    final candidates = [
      ...readPersistentValueCandidates(appStateStorageKey),
      ...readPersistentValueCandidates(legacyAppStateStorageKey),
    ];
    for (final raw in candidates) {
      if (raw.trim().isEmpty) continue;
      try {
        return AppSnapshotCodec.decodeTrustedSnapshot(raw);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  AppSnapshot _mergeSetupIntoSnapshot(
    AppSnapshot snapshot,
    StoreSetupData setup,
  ) {
    final hasOperationalData = _hasOperationalData(snapshot);
    final canReplaceStarterWarehouse =
        !hasOperationalData &&
        snapshot.warehouses.length == 1 &&
        snapshot.warehouses.first.id == 'main';

    final updatedCompany = snapshot.company.copyWith(
      name: setup.normalizedStoreName,
      taxId: setup.taxId.trim(),
      address: setup.address.trim(),
      city: setup.city.trim(),
      phone: setup.phone.trim(),
      email: setup.email.trim(),
      logoSource: snapshot.company.logoSource.trim().isEmpty
          ? AppAssets.systemLogoSource
          : snapshot.company.logoSource,
      invoiceFooter: snapshot.company.invoiceFooter.trim().isEmpty
          ? 'Merci pour votre confiance.'
          : snapshot.company.invoiceFooter,
      timbreFiscalEnabled: setup.timbreFiscal,
      timbreFiscalAmount: snapshot.company.timbreFiscalAmount <= 0
          ? 1
          : snapshot.company.timbreFiscalAmount,
    );

    final starterWarehouse = Warehouse(
      id: 'main',
      name: setup.normalizedDepotName,
      city: setup.normalizedDepotCity,
      code: setup.normalizedDepotCode,
      address: setup.depotAddress.trim(),
    );

    final warehouses = snapshot.warehouses.isEmpty
        ? [starterWarehouse]
        : [
            for (final warehouse in snapshot.warehouses)
              if (canReplaceStarterWarehouse && warehouse.id == 'main')
                starterWarehouse
              else
                warehouse,
          ];

    final categories = snapshot.categories.isEmpty
        ? [Category(id: 'cat-default', name: setup.defaultCategoryName)]
        : snapshot.categories;

    return AppSnapshot(
      company: updatedCompany,
      warehouses: warehouses,
      categories: categories,
      products: snapshot.products,
      partners: snapshot.partners,
      documents: snapshot.documents,
      movements: snapshot.movements,
      sequences: snapshot.sequences.isEmpty
          ? {for (final type in DocumentType.values) type: 1}
          : snapshot.sequences,
      auditEvents: snapshot.auditEvents,
    );
  }
}
