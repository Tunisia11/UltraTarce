import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/local/app_snapshot_local_data_source.dart';
import 'package:ultra_trace/data/repositories/app_repository.dart';
import 'package:ultra_trace/data/repositories/audit_repository.dart';
import 'package:ultra_trace/data/repositories/backup_repository.dart';
import 'package:ultra_trace/data/repositories/category_repository.dart';
import 'package:ultra_trace/data/repositories/client_repository.dart';
import 'package:ultra_trace/data/repositories/company_repository.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/data/repositories/supplier_repository.dart';
import 'package:ultra_trace/data/repositories/warehouse_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/storage/app_storage.dart';

const testWarehouseId = 'wh-main';

void configureInventoryApplicationTestStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? storageDirectory;
  setUp(() {
    storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_inventory_application_test_',
    );
    setPersistentStorageDirectoryForTesting(storageDirectory!.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    final directory = storageDirectory;
    if (directory != null && directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
    storageDirectory = null;
  });
}

class TestRepositories {
  TestRepositories(this.appRepository)
    : productRepository = ProductRepository(appRepository),
      warehouseRepository = WarehouseRepository(appRepository),
      categoryRepository = CategoryRepository(appRepository),
      clientRepository = ClientRepository(appRepository),
      supplierRepository = SupplierRepository(appRepository),
      documentRepository = DocumentRepository(appRepository),
      stockRepository = StockRepository(appRepository),
      companyRepository = CompanyRepository(appRepository),
      backupRepository = BackupRepository(appRepository),
      auditRepository = AuditRepository(appRepository);

  final AppRepository appRepository;
  final ProductRepository productRepository;
  final WarehouseRepository warehouseRepository;
  final CategoryRepository categoryRepository;
  final ClientRepository clientRepository;
  final SupplierRepository supplierRepository;
  final DocumentRepository documentRepository;
  final StockRepository stockRepository;
  final CompanyRepository companyRepository;
  final BackupRepository backupRepository;
  final AuditRepository auditRepository;
}

TestRepositories createTestRepositories({AppSnapshot? snapshot}) {
  final initialSnapshot = snapshot ?? testSnapshot();
  final appRepository = AppRepository(
    AppSnapshotLocalDataSource(fallbackSnapshot: initialSnapshot),
  );
  appRepository.setSnapshot(initialSnapshot, status: 'Test prêt.');
  return TestRepositories(appRepository);
}

AppSnapshot testSnapshot({
  CompanyProfile? company,
  List<Product> products = const [],
  List<Partner> partners = const [],
  List<BusinessDocument> documents = const [],
  List<StockMovement> movements = const [],
  List<AuditEvent> auditEvents = const [],
}) {
  return AppSnapshot(
    company: company ?? testCompany(),
    warehouses: const [
      Warehouse(id: testWarehouseId, name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-main', name: 'Général')],
    products: products,
    partners: partners,
    documents: documents,
    movements: movements,
    sequences: {
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

CompanyProfile testCompany({bool timbreFiscalEnabled = true}) {
  return CompanyProfile(
    name: 'Trace Ultra Test',
    taxId: '0000000/A/M/000',
    address: 'Rue Test',
    city: 'Tunis',
    phone: '70000000',
    email: 'test@example.com',
    logoSource: '',
    invoiceFooter: 'Merci pour votre confiance.',
    timbreFiscalEnabled: timbreFiscalEnabled,
    timbreFiscalAmount: 1,
  );
}

Product testProduct({
  String id = 'p1',
  String name = 'Article test',
  String sku = 'ART-001',
  double saleHt = 100,
  int stock = 0,
  int minStock = 2,
  bool stockTracked = true,
}) {
  return Product(
    id: id,
    name: name,
    sku: sku,
    category: 'Général',
    purchaseHt: 70,
    saleHt: saleHt,
    tvaRate: TvaRate.rate19,
    minStock: minStock,
    serialTracked: false,
    stockTracked: stockTracked,
    stockByWarehouse: {testWarehouseId: stock},
    serialsByWarehouse: const {testWarehouseId: []},
    imageUrl: '',
  );
}

Partner testClient({String id = 'c1', String name = 'Client Test'}) {
  return Partner(
    id: id,
    type: PartnerType.client,
    name: name,
    taxId: '1234567/A/M/000',
    address: 'Adresse client',
    phone: '71000000',
    email: 'client@example.com',
  );
}

Partner testSupplier({String id = 's1', String name = 'Fournisseur Test'}) {
  return Partner(
    id: id,
    type: PartnerType.supplier,
    name: name,
    taxId: '7654321/A/M/000',
    address: 'Adresse fournisseur',
    phone: '72000000',
    email: 'supplier@example.com',
  );
}

BusinessDocument testInvoice({
  String id = 'doc1',
  String number = 'FAC-2026-0001',
  Product? product,
  Partner? client,
  DocumentStatus status = DocumentStatus.validated,
  List<PaymentEntry> payments = const [],
  DateTime? date,
}) {
  final invoiceProduct = product ?? testProduct();
  final invoiceClient = client ?? testClient();
  return BusinessDocument(
    id: id,
    type: DocumentType.facture,
    number: number,
    status: status,
    partnerId: invoiceClient.id,
    partnerName: invoiceClient.name,
    partnerTaxId: invoiceClient.taxId,
    partnerAddress: invoiceClient.address,
    date: date ?? DateTime.now(),
    lines: [
      DocumentLine(
        productId: invoiceProduct.id,
        label: invoiceProduct.name,
        sku: invoiceProduct.sku,
        quantity: 1,
        unitHt: invoiceProduct.saleHt,
        tvaRate: invoiceProduct.tvaRate,
      ),
    ],
    warehouseId: testWarehouseId,
    applyTimbreFiscal: false,
    payments: payments,
  );
}

String testFormatMoney(double value) => value.toStringAsFixed(3);

String testSerialGenerator(String sku, int index) => '$sku-S${index + 1}';
