import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class StockMapper {
  static StockMovementsCompanion toCompanion(
    StockMovement movement, {
    required int index,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final quantityDelta = movement.direction == StockDirection.inbound
        ? movement.quantity
        : -movement.quantity;
    return StockMovementsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, _idFor(movement, index))),
      tenantId: Value(tenantId),
      productId: Value(TenantRowScope.rowId(tenantId, movement.productId)),
      productName: Value(movement.productName),
      warehouseId: Value(TenantRowScope.rowId(tenantId, movement.warehouseId)),
      quantityDelta: Value(quantityDelta),
      type: Value(movement.direction.name),
      reason: Value(movement.reason ?? movement.documentNumber),
      direction: Value(movement.direction.name),
      documentNumber: Value(movement.documentNumber),
      createdAt: Value(movement.date),
      note: Value(movement.note),
      serialNumbersJson: Value(jsonEncode(movement.serialNumbers)),
    );
  }

  static StockMovement fromRow(
    StockMovementRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return StockMovement(
      date: row.createdAt,
      productId: TenantRowScope.domainId(tenantId, row.productId),
      productName: row.productName,
      documentNumber: row.documentNumber,
      direction: enumFromName(
        StockDirection.values,
        row.direction,
        row.quantityDelta >= 0
            ? StockDirection.inbound
            : StockDirection.outbound,
      ),
      quantity: row.quantityDelta.abs(),
      warehouseId: TenantRowScope.domainId(tenantId, row.warehouseId),
      serialNumbers: List<String>.from(
        jsonDecode(row.serialNumbersJson) as List? ?? const [],
      ),
      reason: row.reason,
      note: row.note,
    );
  }

  static String _idFor(StockMovement movement, int index) {
    return [
      movement.date.microsecondsSinceEpoch,
      movement.productId,
      movement.warehouseId,
      movement.documentNumber,
      movement.direction.name,
      index,
    ].join(':');
  }
}
