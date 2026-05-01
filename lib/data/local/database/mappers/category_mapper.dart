import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class CategoryMapper {
  static CategoriesCompanion toCompanion(
    Category category, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return CategoriesCompanion(
      id: Value(TenantRowScope.rowId(tenantId, category.id)),
      tenantId: Value(tenantId),
      name: Value(category.name),
      isActive: Value(category.active),
      updatedAt: Value(now),
      deletedAt: Value(category.active ? null : now),
    );
  }

  static Category fromRow(
    CategoryRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return Category(
      id: TenantRowScope.domainId(tenantId, row.id),
      name: row.name,
      active: row.isActive,
    );
  }
}
