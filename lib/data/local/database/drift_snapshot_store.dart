import 'dart:convert';

import '../../../app/tenant_context.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/sequence_service.dart';
import 'app_database.dart';
import 'mappers/audit_mapper.dart';
import 'mappers/category_mapper.dart';
import 'mappers/company_mapper.dart';
import 'mappers/document_mapper.dart';
import 'mappers/partner_mapper.dart';
import 'mappers/product_mapper.dart';
import 'mappers/stock_mapper.dart';
import 'mappers/warehouse_mapper.dart';

class DriftSnapshotStore {
  DriftSnapshotStore(this.database, {TenantContext? tenantContext})
    : tenantContext = tenantContext ?? const TenantContext();

  static const sequencesSettingKey = 'document_sequences';
  static const legacyMigrationSettingKey = 'legacy_json_migrated';

  final AppDatabase database;
  final TenantContext tenantContext;

  String get _tenantId => tenantContext.selectedTenantId;

  Future<bool> isEmpty() async {
    final tenantId = _tenantId;
    final company = await database.companyDao.getCompany(tenantId: tenantId);
    if (company != null) return false;
    final products = await database.productDao.getAllProducts(
      tenantId: tenantId,
    );
    final clients = await database.partnerDao.getClients(tenantId: tenantId);
    final suppliers = await database.partnerDao.getSuppliers(
      tenantId: tenantId,
    );
    final documents = await database.documentDao.getDocuments(
      tenantId: tenantId,
    );
    return products.isEmpty &&
        clients.isEmpty &&
        suppliers.isEmpty &&
        documents.isEmpty;
  }

  Future<AppSnapshot?> loadSnapshot() async {
    final tenantId = _tenantId;
    final companyRow = await database.companyDao.getCompany(tenantId: tenantId);
    if (companyRow == null) return null;

    final productRows = await database.productDao.getAllProducts(
      tenantId: tenantId,
    );
    final clientRows = await database.partnerDao.getClients(tenantId: tenantId);
    final supplierRows = await database.partnerDao.getSuppliers(
      tenantId: tenantId,
    );
    final documentRows = await database.documentDao.getDocuments(
      tenantId: tenantId,
    );
    final movementRows = await database.stockDao.getMovements(
      tenantId: tenantId,
    );
    final categoryRows = await database.categoryDao.getCategories(
      tenantId: tenantId,
    );
    final warehouseRows = await database.warehouseDao.getWarehouses(
      tenantId: tenantId,
    );
    final auditRows = await database.auditDao.getAuditEvents(
      tenantId: tenantId,
    );

    final documents = <BusinessDocument>[];
    for (final documentRow in documentRows) {
      final bundle = await database.documentDao.getDocumentWithLinesAndPayments(
        documentRow.id,
        tenantId: tenantId,
      );
      if (bundle == null) continue;
      documents.add(
        DocumentMapper.fromRows(
          document: bundle.document,
          lines: bundle.lines,
          payments: bundle.payments,
          tenantId: tenantId,
        ),
      );
    }

    return AppSnapshot(
      company: CompanyMapper.fromRow(companyRow),
      warehouses: warehouseRows
          .map((row) => WarehouseMapper.fromRow(row, tenantId: tenantId))
          .toList(),
      categories: categoryRows
          .map((row) => CategoryMapper.fromRow(row, tenantId: tenantId))
          .toList(),
      products: productRows
          .map((row) => ProductMapper.fromRow(row, tenantId: tenantId))
          .toList(),
      partners: [
        ...clientRows.map(
          (row) => PartnerMapper.fromRow(row, tenantId: tenantId),
        ),
        ...supplierRows.map(
          (row) => PartnerMapper.fromRow(row, tenantId: tenantId),
        ),
      ],
      documents: documents,
      movements: movementRows
          .map((row) => StockMapper.fromRow(row, tenantId: tenantId))
          .toList(),
      sequences: _decodeSequences(
        await database.settingsDao.getSetting(
          sequencesSettingKey,
          tenantId: tenantId,
        ),
        documents,
      ),
      auditEvents: auditRows
          .map((row) => AuditMapper.fromRow(row, tenantId: tenantId))
          .toList(),
    );
  }

  Future<void> replaceSnapshot(AppSnapshot snapshot) async {
    final tenantId = _tenantId;
    await database.transaction(() async {
      await _deleteTenantRows(tenantId);

      await database.companyDao.upsertCompany(
        CompanyMapper.toCompanion(snapshot.company, tenantId: tenantId),
      );

      for (var index = 0; index < snapshot.warehouses.length; index++) {
        await database.warehouseDao.upsertWarehouse(
          WarehouseMapper.toCompanion(
            snapshot.warehouses[index],
            isDefault: index == 0,
            tenantId: tenantId,
          ),
        );
      }
      for (final category in snapshot.categories) {
        await database.categoryDao.upsertCategory(
          CategoryMapper.toCompanion(category, tenantId: tenantId),
        );
      }
      for (final product in snapshot.products) {
        await database.productDao.upsertProduct(
          ProductMapper.toCompanion(product, tenantId: tenantId),
        );
      }
      for (final partner in snapshot.partners) {
        await database.partnerDao.upsertPartner(
          PartnerMapper.toCompanion(partner, tenantId: tenantId),
        );
      }
      for (final document in snapshot.documents) {
        await database.documentDao.upsertDocumentWithLines(
          document: DocumentMapper.toDocumentCompanion(
            document,
            tenantId: tenantId,
          ),
          lines: DocumentMapper.toLineCompanions(document, tenantId: tenantId),
          payments: DocumentMapper.toPaymentCompanions(
            document,
            tenantId: tenantId,
          ),
        );
      }
      for (var index = 0; index < snapshot.movements.length; index++) {
        await database.stockDao.addMovement(
          StockMapper.toCompanion(
            snapshot.movements[index],
            index: index,
            tenantId: tenantId,
          ),
        );
      }
      for (final event in snapshot.auditEvents) {
        await database.auditDao.addAuditEvent(
          AuditMapper.toCompanion(event, tenantId: tenantId),
        );
      }
      await database.settingsDao.setSetting(
        sequencesSettingKey,
        jsonEncode(
          snapshot.sequences.map((type, value) => MapEntry(type.name, value)),
        ),
        tenantId: tenantId,
      );
    });
  }

  Future<void> _deleteTenantRows(String tenantId) async {
    await (database.delete(
      database.payments,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.documentLines,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.documents,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.stockMovements,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.products,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.partners,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.warehouses,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.categories,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.auditEvents,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.companies,
    )..where((table) => table.tenantId.equals(tenantId))).go();
    await (database.delete(
      database.settings,
    )..where((table) => table.tenantId.equals(tenantId))).go();
  }

  Map<DocumentType, int> _decodeSequences(
    String? raw,
    List<BusinessDocument> documents,
  ) {
    final decoded = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final sequences = decoded.map(
      (key, value) => MapEntry(
        enumFromName(DocumentType.values, key, DocumentType.devis),
        (value as num? ?? 1).toInt(),
      ),
    );
    return SequenceService.reconcile(
      sequences: sequences.isEmpty
          ? SequenceService.initialSequences()
          : sequences,
      documents: documents,
    );
  }
}
