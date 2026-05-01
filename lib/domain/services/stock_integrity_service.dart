import '../app_models.dart';

class StockIntegrityService {
  const StockIntegrityService._();

  static String nextMovementNumber(
    Iterable<StockMovement> movements,
    String prefix, {
    DateTime? now,
  }) {
    final year = (now ?? DateTime.now()).year;
    final base = '$prefix-$year-';
    var next = 1;
    for (final movement in movements) {
      if (!movement.documentNumber.startsWith(base)) continue;
      final value = int.tryParse(
        movement.documentNumber.substring(base.length),
      );
      if (value != null && value >= next) {
        next = value + 1;
      }
    }
    return '$base${next.toString().padLeft(4, '0')}';
  }

  static String? serialActionError({
    required Product product,
    required String warehouseId,
    required int quantity,
    required List<String> serialNumbers,
    required bool inbound,
  }) {
    if (!product.serialTracked) return null;
    final available = product.serialsIn(warehouseId);
    final uniqueSerials = serialNumbers.toSet();
    if (serialNumbers.length != uniqueSerials.length) {
      return 'Numéros de série dupliqués pour ${product.name}.';
    }

    if (inbound) {
      if (serialNumbers.isNotEmpty && serialNumbers.length != quantity) {
        return 'Saisissez $quantity numéro(s) de série pour ${product.name}, ou laissez vide pour génération automatique.';
      }
      final alreadyInStock = serialNumbers.where(available.contains).toList();
      if (alreadyInStock.isNotEmpty) {
        return 'Série déjà présente en stock: ${alreadyInStock.join(', ')}.';
      }
      return null;
    }

    if (available.length < quantity) {
      return 'Séries insuffisantes pour ${product.name}: ${available.length} disponible(s), $quantity demandé(s).';
    }
    if (serialNumbers.length != quantity) {
      return 'Sélectionnez exactement $quantity numéro(s) de série pour cette sortie.';
    }
    final missing = serialNumbers.where(
      (serial) => !available.contains(serial),
    );
    if (missing.isNotEmpty) {
      return 'Séries indisponibles dans ce dépôt: ${missing.join(', ')}.';
    }
    return null;
  }

  static String? inboundSerialErrorFor({
    required List<DocumentLine> lines,
    required String warehouseId,
    required Product Function(String productId) productById,
  }) {
    for (final line in lines) {
      final product = productById(line.productId);
      final error = serialActionError(
        product: product,
        warehouseId: warehouseId,
        quantity: line.quantity,
        serialNumbers: line.serialNumbers,
        inbound: true,
      );
      if (error != null) return error;
    }
    return null;
  }
}
