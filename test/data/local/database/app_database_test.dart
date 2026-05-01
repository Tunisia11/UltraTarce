import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/local/database/drift_snapshot_store.dart';
import 'package:ultra_trace/data/local/database/mappers/audit_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/category_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/company_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/document_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/partner_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/product_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/stock_mapper.dart';
import 'package:ultra_trace/data/local/database/mappers/warehouse_mapper.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';

import '../../repositories/drift_repository_test_helpers.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('database opens and stores core inventory rows', () async {
    final product = testProduct(stock: 1, minStock: 2);
    final client = testPartner();
    final supplier = testPartner(
      id: 's1',
      type: PartnerType.supplier,
      name: 'Fournisseur Test',
    );
    final document = testDocument(
      payments: [
        PaymentEntry(
          id: 'pay1',
          date: DateTime(2026, 5, 1),
          amount: 119,
          method: PaymentMethod.cash,
        ),
      ],
    );
    final movement = StockMovement(
      date: DateTime(2026, 5, 1),
      productId: product.id,
      productName: product.name,
      documentNumber: 'AJ-001',
      direction: StockDirection.inbound,
      quantity: 4,
      warehouseId: 'wh-main',
    );

    await database.companyDao.upsertCompany(
      CompanyMapper.toCompanion(testSnapshot().company),
    );
    await database.warehouseDao.upsertWarehouse(
      WarehouseMapper.toCompanion(testSnapshot().warehouses.first),
    );
    await database.categoryDao.upsertCategory(
      CategoryMapper.toCompanion(testSnapshot().categories.first),
    );
    await database.productDao.upsertProduct(ProductMapper.toCompanion(product));
    await database.partnerDao.upsertPartner(PartnerMapper.toCompanion(client));
    await database.partnerDao.upsertPartner(
      PartnerMapper.toCompanion(supplier),
    );
    await database.documentDao.upsertDocumentWithLines(
      document: DocumentMapper.toDocumentCompanion(document),
      lines: DocumentMapper.toLineCompanions(document),
      payments: DocumentMapper.toPaymentCompanions(document),
    );
    await database.stockDao.addMovement(
      StockMapper.toCompanion(movement, index: 0),
    );
    await database.auditDao.addAuditEvent(
      AuditMapper.toCompanion(
        AuditEvent(
          id: 'audit1',
          date: DateTime(2026, 5, 1),
          actor: 'Système',
          action: 'Création',
          target: 'Produit',
          detail: 'Article créé',
        ),
      ),
    );

    expect(await database.productDao.getProductById(product.id), isNotNull);
    expect(await database.partnerDao.getClients(), hasLength(1));
    expect(await database.partnerDao.getSuppliers(), hasLength(1));
    expect(
      await database.documentDao.getDocumentWithLinesAndPayments(document.id),
      isNotNull,
    );
    expect(await database.stockDao.getCurrentStock(product.id, 'wh-main'), 4);
    expect(await database.stockDao.getLowStockProducts(), hasLength(1));
    expect(await database.auditDao.getAuditEvents(), hasLength(1));
  });

  test('snapshot store restores AppSnapshot-compatible data', () async {
    final store = DriftSnapshotStore(database);
    final snapshot = testSnapshot(
      products: [testProduct()],
      partners: [testPartner()],
      documents: [testDocument()],
    );

    await store.replaceSnapshot(snapshot);
    final restored = await store.loadSnapshot();

    expect(restored, isNotNull);
    expect(restored!.products.single.name, 'Article test');
    expect(restored.partners.single.name, 'Client Test');
    expect(restored.documents.single.netToPay, 239);
  });
}
