import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/onboarding/models/store_setup_data.dart';
import 'package:ultra_trace/features/onboarding/services/onboarding_service.dart';
import 'package:ultra_trace/storage/app_snapshot_codec.dart';
import 'package:ultra_trace/storage/app_storage.dart';
import 'package:ultra_trace/storage/app_storage_keys.dart';

void main() {
  late Directory storageDirectory;
  const service = OnboardingService();

  setUp(() {
    storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_onboarding_service_',
    );
    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    deletePersistentValue(appStateStorageKey);
    deletePersistentValue(legacyAppStateStorageKey);
    deletePersistentValue(onboardingCompletedStorageKey);
    deletePersistentValue(onboardingStoreSetupStorageKey);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
  });

  test('requires onboarding when there is no saved business state', () {
    final launchState = service.loadLaunchState();

    expect(launchState.shouldShowOnboarding, isTrue);
    expect(launchState.initialSetup.storeName, isEmpty);
  });

  test(
    'skips onboarding when operational data exists even without completion flag',
    () {
      final snapshot = AppSnapshot(
        company: const CompanyProfile(
          name: 'Tech Nord',
          taxId: '',
          address: '',
          city: '',
          phone: '',
          email: '',
          logoSource: '',
          invoiceFooter: 'Merci.',
        ),
        warehouses: const [
          Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
        ],
        categories: const [Category(id: 'cat-default', name: 'Électronique')],
        products: const [
          Product(
            id: 'p1',
            name: 'TV',
            sku: 'TV-01',
            category: 'Électronique',
            purchaseHt: 100,
            saleHt: 120,
            tvaRate: TvaRate.rate19,
            minStock: 1,
            serialTracked: false,
            stockByWarehouse: {'main': 2},
            serialsByWarehouse: {'main': []},
            imageUrl: '',
          ),
        ],
        partners: const [],
        documents: const [],
        movements: const [],
        sequences: {DocumentType.facture: 1},
        auditEvents: const [],
      );

      writePersistentValue(appStateStorageKey, jsonEncode(snapshot.toJson()));

      final launchState = service.loadLaunchState();

      expect(launchState.shouldShowOnboarding, isFalse);
      expect(launchState.initialSetup.storeName, 'Tech Nord');
    },
  );

  test('completing onboarding merges identity without wiping live data', () {
    final existingSnapshot = AppSnapshot(
      company: const CompanyProfile(
        name: 'Nouveau magasin',
        taxId: '',
        address: '',
        city: '',
        phone: '',
        email: '',
        logoSource: '',
        invoiceFooter: 'Merci.',
      ),
      warehouses: const [
        Warehouse(id: 'main', name: 'Dépôt principal', city: ''),
      ],
      categories: const [Category(id: 'cat-default', name: 'Électronique')],
      products: const [
        Product(
          id: 'p1',
          name: 'iPhone 15',
          sku: 'APL-15',
          category: 'Électronique',
          purchaseHt: 3000,
          saleHt: 3600,
          tvaRate: TvaRate.rate19,
          minStock: 1,
          serialTracked: false,
          stockByWarehouse: {'main': 3},
          serialsByWarehouse: {'main': []},
          imageUrl: '',
        ),
      ],
      partners: const [
        Partner(
          id: 'c1',
          type: PartnerType.client,
          name: 'Client test',
          taxId: '',
          address: 'Sousse',
          phone: '20000000',
          email: 'client@example.tn',
        ),
      ],
      documents: const [],
      movements: const [],
      sequences: {DocumentType.facture: 2},
      auditEvents: const [],
    );

    writePersistentValue(
      appStateStorageKey,
      jsonEncode(existingSnapshot.toJson()),
    );

    service.completeSetup(
      const StoreSetupData(
        storeName: 'Trace Ultra Store',
        taxId: '1234567/A/M/000',
        address: 'Avenue Habib Bourguiba',
        city: 'Tunis',
        phone: '+216 20 000 000',
        email: 'contact@trace.tn',
        commerceType: 'Électronique',
        depotName: 'Dépôt Tunis Centre',
        depotCode: 'TUN-C',
        depotCity: 'Tunis',
        depotAddress: 'Centre-ville',
        priceMode: 'Prix TTC',
        timbreFiscal: true,
      ),
    );

    final raw = readPersistentValue(appStateStorageKey);
    expect(raw, isNotNull);

    final restored = AppSnapshotCodec.decodeTrustedSnapshot(raw!);

    expect(restored.company.name, 'Trace Ultra Store');
    expect(restored.company.taxId, '1234567/A/M/000');
    expect(restored.company.city, 'Tunis');
    expect(restored.products.single.name, 'iPhone 15');
    expect(restored.partners.single.name, 'Client test');
    expect(readPersistentValue(onboardingCompletedStorageKey), 'true');
  });
}
