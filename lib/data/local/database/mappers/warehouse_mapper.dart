import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class WarehouseMapper {
  static WarehousesCompanion toCompanion(
    Warehouse warehouse, {
    bool isDefault = false,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return WarehousesCompanion(
      id: Value(TenantRowScope.rowId(tenantId, warehouse.id)),
      tenantId: Value(tenantId),
      name: Value(warehouse.name),
      code: Value(warehouse.code),
      city: Value(warehouse.city),
      address: Value(warehouse.address),
      isDefault: Value(isDefault),
      isActive: Value(warehouse.active),
      updatedAt: Value(now),
      deletedAt: Value(warehouse.active ? null : now),
    );
  }

  static Warehouse fromRow(
    WarehouseRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return Warehouse(
      id: TenantRowScope.domainId(tenantId, row.id),
      name: row.name,
      city: row.city,
      code: row.code,
      address: row.address,
      active: row.isActive,
    );
  }
}
