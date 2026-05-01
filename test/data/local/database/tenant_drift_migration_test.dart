import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';

void main() {
  test('existing Drift rows are backfilled to the selected tenant', () async {
    const tenantId = 'tenant-a';
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(setup: _createLegacyV1Schema),
      tenantContext: const TenantContext(tenantIdOverride: tenantId),
    );
    addTearDown(database.close);

    final products = await database.productDao.getAllProducts(
      tenantId: tenantId,
    );
    final otherTenantProducts = await database.productDao.getAllProducts(
      tenantId: 'tenant-b',
    );

    expect(products, hasLength(1));
    expect(products.single.tenantId, tenantId);
    expect(products.single.id, '$tenantId::legacy-product');
    expect(otherTenantProducts, isEmpty);
  });
}

void _createLegacyV1Schema(dynamic db) {
  db.execute('''
CREATE TABLE companies (
  id TEXT NOT NULL PRIMARY KEY DEFAULT 'default',
  name TEXT NOT NULL,
  legal_name TEXT NULL,
  tax_id TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  logo_path TEXT NULL,
  logo_source TEXT NOT NULL DEFAULT '',
  invoice_footer TEXT NOT NULL DEFAULT '',
  legal_info TEXT NOT NULL DEFAULT '',
  timbre_fiscal_enabled INTEGER NOT NULL DEFAULT 1,
  timbre_fiscal_amount REAL NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
''');
  db.execute('''
CREATE TABLE warehouses (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  description TEXT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE categories (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE products (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NULL,
  description TEXT NOT NULL DEFAULT '',
  category_id TEXT NULL,
  category_name TEXT NOT NULL DEFAULT '',
  brand TEXT NOT NULL DEFAULT '',
  unit TEXT NOT NULL DEFAULT 'pcs',
  purchase_price_ht REAL NOT NULL DEFAULT 0,
  sale_price_ht REAL NOT NULL DEFAULT 0,
  tva_rate TEXT NOT NULL DEFAULT 'rate19',
  stock_minimum INTEGER NOT NULL DEFAULT 0,
  image_path TEXT NOT NULL DEFAULT '',
  stock_by_warehouse_json TEXT NOT NULL DEFAULT '{}',
  serials_by_warehouse_json TEXT NOT NULL DEFAULT '{}',
  serial_tracked INTEGER NOT NULL DEFAULT 0,
  stock_tracked INTEGER NOT NULL DEFAULT 1,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE partners (
  id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  tax_id TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  customer_type TEXT NOT NULL DEFAULT 'entreprise',
  company_name TEXT NOT NULL DEFAULT '',
  contact_name TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE documents (
  id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL,
  status TEXT NOT NULL,
  number TEXT NOT NULL,
  sequence INTEGER NOT NULL DEFAULT 0,
  partner_id TEXT NOT NULL DEFAULT '',
  partner_name TEXT NOT NULL DEFAULT '',
  partner_tax_id TEXT NOT NULL DEFAULT '',
  partner_address TEXT NOT NULL DEFAULT '',
  issue_date INTEGER NOT NULL,
  due_date INTEGER NULL,
  warehouse_id TEXT NOT NULL DEFAULT '',
  source_document_id TEXT NULL,
  source_number TEXT NULL,
  notes TEXT NULL,
  stock_applied INTEGER NOT NULL DEFAULT 0,
  apply_timbre_fiscal INTEGER NOT NULL DEFAULT 0,
  subtotal_ht REAL NOT NULL DEFAULT 0,
  total_discount REAL NOT NULL DEFAULT 0,
  total_tva REAL NOT NULL DEFAULT 0,
  timbre_fiscal REAL NOT NULL DEFAULT 0,
  total_ttc REAL NOT NULL DEFAULT 0,
  paid_amount REAL NOT NULL DEFAULT 0,
  remaining_amount REAL NOT NULL DEFAULT 0,
  company_snapshot_json TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE document_lines (
  id TEXT NOT NULL PRIMARY KEY,
  document_id TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  product_id TEXT NULL,
  label TEXT NOT NULL,
  sku TEXT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  unit_price_ht REAL NOT NULL DEFAULT 0,
  discount REAL NOT NULL DEFAULT 0,
  tva_rate TEXT NOT NULL DEFAULT 'rate19',
  total_ht REAL NOT NULL DEFAULT 0,
  total_tva REAL NOT NULL DEFAULT 0,
  total_ttc REAL NOT NULL DEFAULT 0,
  serial_numbers_json TEXT NOT NULL DEFAULT '[]',
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
''');
  db.execute('''
CREATE TABLE payments (
  id TEXT NOT NULL PRIMARY KEY,
  document_id TEXT NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  method TEXT NOT NULL DEFAULT 'cash',
  date INTEGER NOT NULL,
  reference TEXT NULL,
  note TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  deleted_at INTEGER NULL
);
''');
  db.execute('''
CREATE TABLE stock_movements (
  id TEXT NOT NULL PRIMARY KEY,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL DEFAULT '',
  warehouse_id TEXT NOT NULL DEFAULT '',
  quantity_delta INTEGER NOT NULL DEFAULT 0,
  type TEXT NOT NULL DEFAULT 'manual',
  reason TEXT NOT NULL DEFAULT '',
  direction TEXT NOT NULL DEFAULT 'inbound',
  document_number TEXT NOT NULL DEFAULT '',
  source_document_id TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  created_by TEXT NULL,
  note TEXT NULL,
  serial_numbers_json TEXT NOT NULL DEFAULT '[]'
);
''');
  db.execute('''
CREATE TABLE audit_events (
  id TEXT NOT NULL PRIMARY KEY,
  type TEXT NOT NULL DEFAULT '',
  title TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  actor TEXT NOT NULL DEFAULT 'Système',
  action TEXT NOT NULL DEFAULT '',
  target TEXT NOT NULL DEFAULT '',
  detail TEXT NOT NULL DEFAULT '',
  entity_type TEXT NULL,
  entity_id TEXT NULL,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  metadata_json TEXT NULL
);
''');
  db.execute('''
CREATE TABLE settings (
  key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
''');
  db.execute(
    "INSERT INTO companies (id, name) VALUES ('default', 'Legacy Company')",
  );
  db.execute(
    "INSERT INTO products (id, name, sku, category_name) VALUES ('legacy-product', 'Produit legacy', 'LEG-001', 'Général')",
  );
  db.execute('PRAGMA user_version = 1');
}
