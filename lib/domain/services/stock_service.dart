import '../app_models.dart';

class StockService {
  const StockService._();

  static String? stockAvailabilityErrorFor({
    required List<DocumentLine> lines,
    required String warehouseId,
    required Product Function(String productId) productById,
    required String Function(String warehouseId) warehouseNameById,
  }) {
    final requiredByProduct = <String, int>{};
    for (final line in lines) {
      requiredByProduct[line.productId] =
          (requiredByProduct[line.productId] ?? 0) + line.quantity;
    }

    for (final entry in requiredByProduct.entries) {
      final product = productById(entry.key);
      if (!product.stockTracked) continue;
      final available = product.stockIn(warehouseId);
      if (entry.value > available) {
        return 'Stock insuffisant pour ${product.name}. ${warehouseNameById(warehouseId)}: $available disponible, ${entry.value} demandé. Réduisez la quantité, changez de magasin ou faites une entrée stock.';
      }
    }
    return null;
  }

  static String? serialSelectionErrorFor({
    required List<DocumentLine> lines,
    required String warehouseId,
    required Product Function(String productId) productById,
  }) {
    for (final line in lines) {
      final product = productById(line.productId);
      if (!product.serialTracked) continue;
      final available = product.serialsIn(warehouseId);
      final selected = line.serialNumbers.toSet();
      if (line.serialNumbers.length != line.quantity) {
        return 'Numéros de série requis pour ${product.name}. Sélectionnez exactement ${line.quantity} numéro(s) via le bouton Séries, puis validez.';
      }
      if (selected.length != line.serialNumbers.length) {
        return 'Numéros de série en double sur ${product.name}. Gardez un seul choix par unité vendue.';
      }
      final missing = selected.where((serial) => !available.contains(serial));
      if (missing.isNotEmpty) {
        return 'Numéro de série indisponible pour ${product.name}: ${missing.join(', ')}. Choisissez une série disponible dans ce magasin.';
      }
    }
    return null;
  }
}
