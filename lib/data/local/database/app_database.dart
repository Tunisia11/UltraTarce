import 'package:drift/drift.dart';

import '../../../app/tenant_context.dart';
import 'database_connection.dart';
import 'tenant_row_scope.dart';

part 'app_database.g.dart';
part 'tables/companies_table.dart';
part 'tables/warehouses_table.dart';
part 'tables/categories_table.dart';
part 'tables/products_table.dart';
part 'tables/partners_table.dart';
part 'tables/documents_table.dart';
part 'tables/document_lines_table.dart';
part 'tables/payments_table.dart';
part 'tables/stock_movements_table.dart';
part 'tables/audit_events_table.dart';
part 'tables/settings_table.dart';
part 'daos/company_dao.dart';
part 'daos/warehouse_dao.dart';
part 'daos/category_dao.dart';
part 'daos/product_dao.dart';
part 'daos/partner_dao.dart';
part 'daos/document_dao.dart';
part 'daos/stock_dao.dart';
part 'daos/audit_dao.dart';
part 'daos/settings_dao.dart';

@DriftDatabase(
  tables: [
    Companies,
    Warehouses,
    Categories,
    Products,
    Partners,
    Documents,
    DocumentLines,
    Payments,
    StockMovements,
    AuditEvents,
    Settings,
  ],
  daos: [
    CompanyDao,
    WarehouseDao,
    CategoryDao,
    ProductDao,
    PartnerDao,
    DocumentDao,
    StockDao,
    AuditDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor, TenantContext? tenantContext])
    : tenantContext = tenantContext ?? const TenantContext(),
      super(executor ?? openDatabaseConnection());

  AppDatabase.forTesting(super.executor, {TenantContext? tenantContext})
    : tenantContext = tenantContext ?? const TenantContext();

  final TenantContext tenantContext;

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await _migrateToTenantScopedRows(migrator);
      }
      if (from < 3) {
        await _migrateToLocalSyncFoundation(migrator);
      }
      if (from < 4) {
        await migrator.addColumn(documents, documents.metadataJson);
        await migrator.addColumn(warehouses, warehouses.type);
      }
      if (from < 5) {
        // Legacy migration if anyone was on v5-preview
        await _ensureFilesTableExists();
      }
      if (from < 6) {
        await _ensureFilesTableExists();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureLocalSyncFoundation();
      await _ensureFilesTableExists();
    },
  );

  Future<void> _migrateToTenantScopedRows(Migrator migrator) async {
    final tenantId = tenantContext.selectedTenantId;
    await migrator.addColumn(companies, companies.tenantId);
    await migrator.addColumn(warehouses, warehouses.tenantId);
    await migrator.addColumn(categories, categories.tenantId);
    await migrator.addColumn(products, products.tenantId);
    await migrator.addColumn(partners, partners.tenantId);
    await migrator.addColumn(documents, documents.tenantId);
    await migrator.addColumn(documentLines, documentLines.tenantId);
    await migrator.addColumn(payments, payments.tenantId);
    await migrator.addColumn(stockMovements, stockMovements.tenantId);
    await migrator.addColumn(auditEvents, auditEvents.tenantId);
    await migrator.addColumn(settings, settings.tenantId);

    await transaction(() async {
      await _backfillTenantIds(tenantId);
      await _scopeLegacyPrimaryKeys(tenantId);
      await _createTenantIndexes();
    });
  }

  Future<void> _migrateToLocalSyncFoundation(Migrator migrator) async {
    await _ensureLocalSyncFoundation();
  }

  Future<void> _ensureFilesTableExists() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS files (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        bucket TEXT NOT NULL,
        path TEXT NOT NULL,
        type TEXT,
        linked_entity_type TEXT,
        linked_entity_id TEXT,
        file_name TEXT,
        mime_type TEXT,
        size_bytes INTEGER,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        created_by TEXT,
        updated_by TEXT,
        version INTEGER DEFAULT 1,
        sync_origin_device_id TEXT,
        UNIQUE(bucket, path)
      )
    ''');
  }

  Future<void> _ensureLocalSyncFoundation() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        device_id TEXT NOT NULL,
        user_id TEXT NULL,
        idempotency_key TEXT NOT NULL UNIQUE
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        tenant_id TEXT NULL,
        value_json TEXT NOT NULL,
        updated_at DATETIME NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_conflicts (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        reason TEXT NOT NULL,
        local_payload_json TEXT NULL,
        remote_payload_json TEXT NULL,
        local_updated_at DATETIME NULL,
        remote_updated_at DATETIME NULL,
        status TEXT NOT NULL DEFAULT 'open',
        created_at DATETIME NOT NULL,
        resolved_at DATETIME NULL,
        resolved_by TEXT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS sync_errors (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        entity_type TEXT NULL,
        entity_id TEXT NULL,
        operation TEXT NULL,
        error_code TEXT NULL,
        error_message TEXT NOT NULL,
        payload_json TEXT NULL,
        created_at DATETIME NOT NULL,
        resolved_at DATETIME NULL
      )
    ''');
    await _createSyncIndexes();
  }

  Future<void> _backfillTenantIds(String tenantId) async {
    for (final table in const [
      'companies',
      'warehouses',
      'categories',
      'products',
      'partners',
      'documents',
      'document_lines',
      'payments',
      'stock_movements',
      'audit_events',
      'settings',
    ]) {
      await customStatement(
        'UPDATE $table SET tenant_id = ? WHERE tenant_id = ?',
        [tenantId, TenantContext.legacyTenantId],
      );
    }
  }

  Future<void> _scopeLegacyPrimaryKeys(String tenantId) async {
    final prefixPattern = '$tenantId${TenantRowScope.separator}%';
    await customStatement(
      'UPDATE companies SET id = ? WHERE tenant_id = ? AND id <> ?',
      [tenantId, tenantId, tenantId],
    );
    for (final table in const [
      'warehouses',
      'categories',
      'products',
      'partners',
      'documents',
      'document_lines',
      'payments',
      'stock_movements',
      'audit_events',
    ]) {
      await customStatement(
        "UPDATE $table SET id = ? || '${TenantRowScope.separator}' || id "
        'WHERE tenant_id = ? AND id NOT LIKE ?',
        [tenantId, tenantId, prefixPattern],
      );
    }

    await _scopeReferenceColumn(
      tenantId,
      table: 'documents',
      column: 'partner_id',
    );
    await _scopeReferenceColumn(
      tenantId,
      table: 'documents',
      column: 'warehouse_id',
    );
    await _scopeNullableReferenceColumn(
      tenantId,
      table: 'documents',
      column: 'source_document_id',
    );
    await _scopeReferenceColumn(
      tenantId,
      table: 'document_lines',
      column: 'document_id',
    );
    await _scopeNullableReferenceColumn(
      tenantId,
      table: 'document_lines',
      column: 'product_id',
    );
    await _scopeReferenceColumn(
      tenantId,
      table: 'payments',
      column: 'document_id',
    );
    await _scopeReferenceColumn(
      tenantId,
      table: 'stock_movements',
      column: 'product_id',
    );
    await _scopeReferenceColumn(
      tenantId,
      table: 'stock_movements',
      column: 'warehouse_id',
    );
    await _scopeNullableReferenceColumn(
      tenantId,
      table: 'stock_movements',
      column: 'source_document_id',
    );
    await customStatement(
      "UPDATE settings SET key = 'tenant:' || ? || '${TenantRowScope.separator}' || key "
      "WHERE tenant_id = ? AND key NOT LIKE 'tenant:%' AND key NOT LIKE 'global:%'",
      [tenantId, tenantId],
    );
  }

  Future<void> _scopeReferenceColumn(
    String tenantId, {
    required String table,
    required String column,
  }) async {
    await customStatement(
      "UPDATE $table SET $column = ? || '${TenantRowScope.separator}' || $column "
      'WHERE tenant_id = ? AND $column <> ? AND $column NOT LIKE ?',
      [tenantId, tenantId, '', '$tenantId${TenantRowScope.separator}%'],
    );
  }

  Future<void> _scopeNullableReferenceColumn(
    String tenantId, {
    required String table,
    required String column,
  }) async {
    await customStatement(
      "UPDATE $table SET $column = ? || '${TenantRowScope.separator}' || $column "
      'WHERE tenant_id = ? AND $column IS NOT NULL AND $column <> ? '
      'AND $column NOT LIKE ?',
      [tenantId, tenantId, '', '$tenantId${TenantRowScope.separator}%'],
    );
  }

  Future<void> _createTenantIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_companies_tenant_id ON companies(tenant_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_warehouses_tenant_name ON warehouses(tenant_id, name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_tenant_name ON categories(tenant_id, name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_tenant_name ON products(tenant_id, name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_tenant_sku ON products(tenant_id, sku)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_tenant_barcode ON products(tenant_id, barcode)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_partners_tenant_type_name ON partners(tenant_id, type, name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_documents_tenant_type_status_issue_date ON documents(tenant_id, type, status, issue_date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_documents_tenant_number ON documents(tenant_id, number)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_document_lines_tenant_document ON document_lines(tenant_id, document_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_payments_tenant_document ON payments(tenant_id, document_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant_product_warehouse_created_at ON stock_movements(tenant_id, product_id, warehouse_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_created_at ON audit_events(tenant_id, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_settings_tenant_key ON settings(tenant_id, key)',
    );
  }

  Future<void> _createSyncIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_tenant_status_created_at ON sync_outbox(tenant_id, status, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_tenant_entity ON sync_outbox(tenant_id, entity_type, entity_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_conflicts_tenant_entity ON sync_conflicts(tenant_id, entity_type, entity_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_errors_tenant_created_at ON sync_errors(tenant_id, created_at)',
    );
  }
}

AppDatabase? _databaseOverrideForTesting;

void setAppDatabaseForTesting(AppDatabase? database) {
  _databaseOverrideForTesting = database;
}

AppDatabase createAppDatabase({TenantContext? tenantContext}) {
  return _databaseOverrideForTesting ?? AppDatabase(null, tenantContext);
}
