import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/app_snapshot_local_data_source.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/local/database/drift_snapshot_store.dart';
import 'package:ultra_trace/data/repositories/app_repository.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';

class DriftRepositoryHarness {
  DriftRepositoryHarness({
    required this.database,
    required this.store,
    required this.appRepository,
    required this.syncOutboxRepository,
  });

  final AppDatabase database;
  final DriftSnapshotStore store;
  final AppRepository appRepository;
  final SyncOutboxRepository syncOutboxRepository;

  Future<void> close() async {
    await syncOutboxRepository.close();
    await database.close();
  }
}

Future<DriftRepositoryHarness> createDriftRepositoryHarness({
  AppSnapshot? snapshot,
  String tenantId = TenantContext.legacyTenantId,
  AppDatabase? databaseOverride,
}) async {
  final tenantContext = TenantContext(tenantIdOverride: tenantId);
  final database =
      databaseOverride ??
      AppDatabase.forTesting(
        NativeDatabase.memory(),
        tenantContext: tenantContext,
      );
  final store = DriftSnapshotStore(database, tenantContext: tenantContext);
  final syncOutboxRepository = SyncOutboxRepository(database);
  final initialSnapshot = snapshot ?? testSnapshot();
  await store.replaceSnapshot(initialSnapshot);
  final appRepository = AppRepository(
    AppSnapshotLocalDataSource(fallbackSnapshot: initialSnapshot),
    driftStore: store,
    tenantContext: tenantContext,
    syncOutboxService: SyncOutboxService(
      repository: syncOutboxRepository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    ),
  )..setSnapshot(initialSnapshot, status: 'Test prêt.');
  if (databaseOverride == null) {
    addTearDown(() async {
      await syncOutboxRepository.close();
      await database.close();
    });
  }
  return DriftRepositoryHarness(
    database: database,
    store: store,
    appRepository: appRepository,
    syncOutboxRepository: syncOutboxRepository,
  );
}

AppSnapshot testSnapshot({
  List<Product> products = const [],
  List<Partner> partners = const [],
  List<BusinessDocument> documents = const [],
  List<StockMovement> movements = const [],
  List<AuditEvent> auditEvents = const [],
}) {
  return AppSnapshot(
    company: const CompanyProfile(
      name: 'Trace Ultra Test',
      taxId: '0000000/A/M/000',
      address: 'Rue Test',
      city: 'Tunis',
      phone: '70000000',
      email: 'test@example.com',
      logoSource: '',
      invoiceFooter: 'Merci pour votre confiance.',
    ),
    warehouses: const [
      Warehouse(id: 'wh-main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-main', name: 'Général')],
    products: products,
    partners: partners,
    documents: documents,
    movements: movements,
    sequences: const {
      DocumentType.devis: 1,
      DocumentType.bl: 1,
      DocumentType.facture: 1,
      DocumentType.creditNote: 1,
      DocumentType.supplierOrder: 1,
      DocumentType.stockEntry: 1,
    },
    auditEvents: auditEvents,
  );
}

Product testProduct({
  String id = 'p1',
  String name = 'Article test',
  int stock = 5,
  int minStock = 2,
}) {
  return Product(
    id: id,
    name: name,
    sku: 'ART-001',
    category: 'Général',
    purchaseHt: 70,
    saleHt: 100,
    tvaRate: TvaRate.rate19,
    minStock: minStock,
    serialTracked: false,
    stockTracked: true,
    stockByWarehouse: {'wh-main': stock},
    serialsByWarehouse: const {'wh-main': []},
    imageUrl: '',
  );
}

Partner testPartner({
  String id = 'c1',
  PartnerType type = PartnerType.client,
  String name = 'Client Test',
}) {
  return Partner(
    id: id,
    type: type,
    name: name,
    taxId: '1234567/A/M/000',
    address: 'Adresse',
    phone: '71000000',
    email: 'contact@example.com',
  );
}

BusinessDocument testDocument({
  String id = 'd1',
  DocumentType type = DocumentType.facture,
  DocumentStatus status = DocumentStatus.validated,
  List<PaymentEntry> payments = const [],
}) {
  return BusinessDocument(
    id: id,
    type: type,
    number: 'FAC-2026-0001',
    status: status,
    partnerId: 'c1',
    partnerName: 'Client Test',
    partnerTaxId: '1234567/A/M/000',
    partnerAddress: 'Adresse',
    date: DateTime(2026, 5, 1),
    lines: const [
      DocumentLine(
        productId: 'p1',
        label: 'Article test',
        sku: 'ART-001',
        quantity: 2,
        unitHt: 100,
        tvaRate: TvaRate.rate19,
      ),
    ],
    warehouseId: 'wh-main',
    applyTimbreFiscal: true,
    timbreFiscalAmount: 1,
    payments: payments,
  );
}
