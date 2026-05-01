import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class ProductMapper {
  static ProductsCompanion toCompanion(
    Product product, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return ProductsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, product.id)),
      tenantId: Value(tenantId),
      name: Value(product.name),
      sku: Value(product.sku),
      barcode: Value(product.barcode),
      description: Value(product.description),
      categoryName: Value(product.category),
      brand: Value(product.brand),
      purchasePriceHt: Value(product.purchaseHt),
      salePriceHt: Value(product.saleHt),
      tvaRate: Value(product.tvaRate.name),
      stockMinimum: Value(product.minStock),
      imagePath: Value(product.imageUrl),
      stockByWarehouseJson: Value(jsonEncode(product.stockByWarehouse)),
      serialsByWarehouseJson: Value(jsonEncode(product.serialsByWarehouse)),
      serialTracked: Value(product.serialTracked),
      stockTracked: Value(product.stockTracked),
      isActive: Value(product.active),
      updatedAt: Value(now),
      deletedAt: Value(product.active ? null : now),
    );
  }

  static Product fromRow(
    ProductRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final stock = _decodeIntMap(row.stockByWarehouseJson);
    final serials = _decodeSerialMap(row.serialsByWarehouseJson);
    return Product(
      id: TenantRowScope.domainId(tenantId, row.id),
      name: row.name,
      sku: row.sku,
      category: row.categoryName,
      purchaseHt: row.purchasePriceHt,
      saleHt: row.salePriceHt,
      tvaRate: enumFromName(TvaRate.values, row.tvaRate, TvaRate.rate19),
      minStock: row.stockMinimum,
      serialTracked: row.serialTracked,
      stockByWarehouse: stock,
      serialsByWarehouse: serials,
      imageUrl: row.imagePath,
      barcode: row.barcode,
      brand: row.brand,
      description: row.description,
      stockTracked: row.stockTracked,
      active: row.isActive,
    );
  }

  static Map<String, int> _decodeIntMap(String raw) {
    final decoded = jsonDecode(raw) as Map? ?? const {};
    return decoded.map(
      (key, value) => MapEntry('$key', (value as num? ?? 0).toInt()),
    );
  }

  static Map<String, List<String>> _decodeSerialMap(String raw) {
    final decoded = jsonDecode(raw) as Map? ?? const {};
    return decoded.map(
      (key, value) =>
          MapEntry('$key', List<String>.from(value as List? ?? const [])),
    );
  }
}
