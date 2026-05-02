import '../app_enums.dart';
import '../app_models.dart';
import 'stock_integrity_service.dart';
import 'stock_service.dart';

class StockMutationResult {
  const StockMutationResult({
    required this.products,
    required this.lines,
    required this.movements,
  });

  final List<Product> products;
  final List<DocumentLine> lines;
  final List<StockMovement> movements;
}

class StockMutationOutcome {
  const StockMutationOutcome.success(this.result) : errorMessage = null;
  const StockMutationOutcome.failure(this.errorMessage) : result = null;

  final StockMutationResult? result;
  final String? errorMessage;

  bool get isSuccess => result != null;
}

class StockMutationService {
  const StockMutationService._();

  static List<Product> lowStockProducts(Iterable<Product> products) {
    return products
        .where(
          (product) =>
              product.active &&
              product.stockTracked &&
              product.totalStock <= product.minStock,
        )
        .toList();
  }

  static int quantityForProductInLines(
    String productId,
    Iterable<DocumentLine> lines,
  ) {
    return lines
        .where((line) => line.productId == productId)
        .fold(0, (total, line) => total + line.quantity);
  }

  static int stockRemainingAfterAdding({
    required Product product,
    required String warehouseId,
    required Iterable<DocumentLine> draftLines,
    required int selectedQuantity,
  }) {
    return product.stockIn(warehouseId) -
        quantityForProductInLines(product.id, draftLines) -
        selectedQuantity;
  }

  static StockMutationOutcome applyInitialStock({
    required List<Product> products,
    required String productId,
    required String warehouseId,
    required int quantity,
    required String movementNumber,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
  }) {
    return applyAdjustment(
      products: products,
      productId: productId,
      warehouseId: warehouseId,
      direction: StockDirection.inbound,
      quantity: quantity,
      serialNumbers: const [],
      movementNumber: movementNumber,
      date: date,
      serialGenerator: serialGenerator,
    );
  }

  static StockMutationResult applyOutboundDocument({
    required List<Product> products,
    required BusinessDocument document,
    required DateTime date,
  }) {
    final updatedProducts = List<Product>.from(products);
    final shippedLines = <DocumentLine>[];
    final movements = <StockMovement>[];

    for (final line in document.lines) {
      final product = _productById(updatedProducts, line.productId);
      if (!product.stockTracked) {
        shippedLines.add(line);
        continue;
      }

      final stock = Map<String, int>.from(product.stockByWarehouse);
      final serials = _copySerials(product.serialsByWarehouse);
      stock[document.warehouseId] =
          (stock[document.warehouseId] ?? 0) - line.quantity;

      var allocatedSerials = <String>[];
      if (product.serialTracked) {
        final availableSerials = serials[document.warehouseId] ?? <String>[];
        allocatedSerials = line.serialNumbers.length == line.quantity
            ? List<String>.from(line.serialNumbers)
            : availableSerials.take(line.quantity).toList();
        serials[document.warehouseId] = availableSerials
            .where((serial) => !allocatedSerials.contains(serial))
            .toList();
      }

      _replaceProduct(
        updatedProducts,
        product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
      );
      movements.insert(
        0,
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.outbound,
          quantity: line.quantity,
          warehouseId: document.warehouseId,
          serialNumbers: allocatedSerials,
        ),
      );
      shippedLines.add(line.copyWith(serialNumbers: allocatedSerials));
    }

    return StockMutationResult(
      products: updatedProducts,
      lines: shippedLines,
      movements: movements,
    );
  }

  static StockMutationResult applyInboundDocument({
    required List<Product> products,
    required BusinessDocument document,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
  }) {
    final updatedProducts = List<Product>.from(products);
    final receivedLines = <DocumentLine>[];
    final movements = <StockMovement>[];

    for (final line in document.lines) {
      final product = _productById(updatedProducts, line.productId);
      if (!product.stockTracked) {
        receivedLines.add(line);
        continue;
      }

      final stock = Map<String, int>.from(product.stockByWarehouse);
      final serials = _copySerials(product.serialsByWarehouse);
      stock[document.warehouseId] =
          (stock[document.warehouseId] ?? 0) + line.quantity;

      final generatedSerials = <String>[];
      if (product.serialTracked) {
        generatedSerials.addAll(line.serialNumbers.take(line.quantity));
        for (var i = generatedSerials.length; i < line.quantity; i++) {
          generatedSerials.add(serialGenerator(product.sku, i));
        }
        serials[document.warehouseId] = [
          ...(serials[document.warehouseId] ?? const <String>[]),
          ...generatedSerials,
        ];
      }

      _replaceProduct(
        updatedProducts,
        product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
      );
      movements.insert(
        0,
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.inbound,
          quantity: line.quantity,
          warehouseId: document.warehouseId,
          serialNumbers: generatedSerials,
        ),
      );
      receivedLines.add(line.copyWith(serialNumbers: generatedSerials));
    }

    return StockMutationResult(
      products: updatedProducts,
      lines: receivedLines,
      movements: movements,
    );
  }

  static StockMutationOutcome reverseDocument({
    required List<Product> products,
    required BusinessDocument document,
    required DateTime date,
    required String Function(String warehouseId) warehouseNameById,
    required String Function(String sku, int index) serialGenerator,
  }) {
    if (document.type == DocumentType.bl ||
        (document.type == DocumentType.facture &&
            document.sourceNumber == null)) {
      final reverseDoc = document.copyForStockReversal(
        type: DocumentType.stockEntry,
        date: date,
      );
      return StockMutationOutcome.success(
        applyInboundDocument(
          products: products,
          document: reverseDoc,
          date: date,
          serialGenerator: serialGenerator,
        ),
      );
    }

    if (document.type == DocumentType.stockEntry ||
        document.type == DocumentType.creditNote) {
      Product productById(String productId) =>
          _productById(products, productId);

      final error = StockService.stockAvailabilityErrorFor(
        lines: document.lines,
        warehouseId: document.warehouseId,
        productById: productById,
        warehouseNameById: warehouseNameById,
      );
      final serialError =
          error ??
          StockService.serialSelectionErrorFor(
            lines: document.lines,
            warehouseId: document.warehouseId,
            productById: productById,
          );
      if (serialError != null) {
        return StockMutationOutcome.failure(
          'Annulation impossible. $serialError Corrigez le stock disponible avant de reprendre cette annulation.',
        );
      }

      final reverseDoc = document.copyForStockReversal(
        type: DocumentType.bl,
        date: date,
      );
      return StockMutationOutcome.success(
        applyOutboundDocument(
          products: products,
          document: reverseDoc,
          date: date,
        ),
      );
    }

    if (document.type == DocumentType.bonSortie) {
      final targetWarehouseId =
          document.metadata['targetWarehouseId'] as String?;
      if (targetWarehouseId == null || targetWarehouseId.isEmpty) {
        return const StockMutationOutcome.failure(
          'Dépôt de destination non défini dans le document.',
        );
      }
      // Reversing transfer: source is now the old target, target is now the old source
      final reverseDoc = document.copyWith(
        warehouseId: targetWarehouseId,
        metadata: {'targetWarehouseId': document.warehouseId},
      );
      return applyTransferDocument(
        products: products,
        document: reverseDoc,
        date: date,
      );
    }

    return StockMutationOutcome.success(
      StockMutationResult(
        products: List<Product>.from(products),
        lines: document.lines,
        movements: const [],
      ),
    );
  }

  static StockMutationOutcome applyAdjustment({
    required List<Product> products,
    required String productId,
    required String warehouseId,
    required StockDirection direction,
    required int quantity,
    required List<String> serialNumbers,
    required String movementNumber,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
    String? reason,
    String? note,
  }) {
    final product = _productById(products, productId);
    if (!product.stockTracked) {
      return const StockMutationOutcome.failure('Produit non suivi en stock.');
    }
    if (direction == StockDirection.outbound &&
        product.stockIn(warehouseId) < quantity) {
      return const StockMutationOutcome.failure(
        'Stock insuffisant pour cette sortie.',
      );
    }
    final serialError = StockIntegrityService.serialActionError(
      product: product,
      warehouseId: warehouseId,
      quantity: quantity,
      serialNumbers: serialNumbers,
      inbound: direction == StockDirection.inbound,
    );
    if (serialError != null) {
      return StockMutationOutcome.failure(serialError);
    }

    final updatedProducts = List<Product>.from(products);
    final stock = Map<String, int>.from(product.stockByWarehouse);
    final serials = _copySerials(product.serialsByWarehouse);
    final current = stock[warehouseId] ?? 0;
    stock[warehouseId] = direction == StockDirection.inbound
        ? current + quantity
        : current - quantity;

    var movementSerials = <String>[];
    if (product.serialTracked) {
      if (direction == StockDirection.inbound) {
        movementSerials = serialNumbers.isEmpty
            ? [
                for (var i = 0; i < quantity; i++)
                  serialGenerator(product.sku, i),
              ]
            : serialNumbers.take(quantity).toList();
        while (movementSerials.length < quantity) {
          movementSerials.add(
            serialGenerator(product.sku, movementSerials.length),
          );
        }
        serials[warehouseId] = [
          ...(serials[warehouseId] ?? const <String>[]),
          ...movementSerials,
        ];
      } else {
        final available = serials[warehouseId] ?? <String>[];
        movementSerials = serialNumbers.take(quantity).toList();
        serials[warehouseId] = available
            .where((serial) => !movementSerials.contains(serial))
            .toList();
      }
    }

    _replaceProduct(
      updatedProducts,
      product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
    );

    return StockMutationOutcome.success(
      StockMutationResult(
        products: updatedProducts,
        lines: const [],
        movements: [
          StockMovement(
            date: date,
            productId: product.id,
            productName: product.name,
            documentNumber: movementNumber,
            direction: direction,
            quantity: quantity,
            warehouseId: warehouseId,
            serialNumbers: movementSerials,
            reason: reason,
            note: note,
          ),
        ],
      ),
    );
  }

  static StockMutationOutcome applyTransfer({
    required List<Product> products,
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    required List<String> serialNumbers,
    required String movementNumber,
    required DateTime date,
    String? reason,
    String? note,
  }) {
    if (fromWarehouseId == toWarehouseId) {
      return const StockMutationOutcome.failure(
        'Choisissez deux dépôts différents.',
      );
    }
    final product = _productById(products, productId);
    if (!product.stockTracked) {
      return const StockMutationOutcome.failure('Produit non suivi en stock.');
    }
    if (product.stockIn(fromWarehouseId) < quantity) {
      return const StockMutationOutcome.failure(
        'Stock insuffisant pour ce transfert.',
      );
    }
    final serialError = StockIntegrityService.serialActionError(
      product: product,
      warehouseId: fromWarehouseId,
      quantity: quantity,
      serialNumbers: serialNumbers,
      inbound: false,
    );
    if (serialError != null) {
      return StockMutationOutcome.failure(serialError);
    }

    final updatedProducts = List<Product>.from(products);
    final stock = Map<String, int>.from(product.stockByWarehouse);
    final serials = _copySerials(product.serialsByWarehouse);
    stock[fromWarehouseId] = (stock[fromWarehouseId] ?? 0) - quantity;
    stock[toWarehouseId] = (stock[toWarehouseId] ?? 0) + quantity;

    var movedSerials = <String>[];
    if (product.serialTracked) {
      final available = serials[fromWarehouseId] ?? <String>[];
      movedSerials = serialNumbers.take(quantity).toList();
      serials[fromWarehouseId] = available
          .where((serial) => !movedSerials.contains(serial))
          .toList();
      serials[toWarehouseId] = [
        ...(serials[toWarehouseId] ?? const <String>[]),
        ...movedSerials,
      ];
    }

    _replaceProduct(
      updatedProducts,
      product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
    );

    return StockMutationOutcome.success(
      StockMutationResult(
        products: updatedProducts,
        lines: const [],
        movements: [
          StockMovement(
            date: date,
            productId: product.id,
            productName: product.name,
            documentNumber: movementNumber,
            direction: StockDirection.outbound,
            quantity: quantity,
            warehouseId: fromWarehouseId,
            serialNumbers: movedSerials,
            reason: reason,
            note: note,
          ),
          StockMovement(
            date: date,
            productId: product.id,
            productName: product.name,
            documentNumber: movementNumber,
            direction: StockDirection.inbound,
            quantity: quantity,
            warehouseId: toWarehouseId,
            serialNumbers: movedSerials,
            reason: reason,
            note: note,
          ),
        ],
      ),
    );
  }

  static StockMutationOutcome applyTransferDocument({
    required List<Product> products,
    required BusinessDocument document,
    required DateTime date,
  }) {
    final targetWarehouseId = document.metadata['targetWarehouseId'] as String?;
    if (targetWarehouseId == null || targetWarehouseId.isEmpty) {
      return const StockMutationOutcome.failure(
        'Dépôt de destination non défini dans le document.',
      );
    }
    if (document.warehouseId == targetWarehouseId) {
      return const StockMutationOutcome.failure(
        'Les dépôts source et destination doivent être différents.',
      );
    }

    final updatedProducts = List<Product>.from(products);
    final processedLines = <DocumentLine>[];
    final movements = <StockMovement>[];

    for (final line in document.lines) {
      final product = _productById(updatedProducts, line.productId);
      if (!product.stockTracked) {
        processedLines.add(line);
        continue;
      }

      if (product.stockIn(document.warehouseId) < line.quantity) {
        return StockMutationOutcome.failure(
          'Stock insuffisant pour ${product.name} dans le dépôt source.',
        );
      }

      final stock = Map<String, int>.from(product.stockByWarehouse);
      final serials = _copySerials(product.serialsByWarehouse);

      stock[document.warehouseId] =
          (stock[document.warehouseId] ?? 0) - line.quantity;
      stock[targetWarehouseId] =
          (stock[targetWarehouseId] ?? 0) + line.quantity;

      var movedSerials = <String>[];
      if (product.serialTracked) {
        final available = serials[document.warehouseId] ?? <String>[];
        movedSerials = line.serialNumbers.length == line.quantity
            ? List<String>.from(line.serialNumbers)
            : available.take(line.quantity).toList();

        serials[document.warehouseId] = available
            .where((serial) => !movedSerials.contains(serial))
            .toList();
        serials[targetWarehouseId] = [
          ...(serials[targetWarehouseId] ?? const <String>[]),
          ...movedSerials,
        ];
      }

      _replaceProduct(
        updatedProducts,
        product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
      );

      movements.add(
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.outbound,
          quantity: line.quantity,
          warehouseId: document.warehouseId,
          serialNumbers: movedSerials,
        ),
      );
      movements.add(
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.inbound,
          quantity: line.quantity,
          warehouseId: targetWarehouseId,
          serialNumbers: movedSerials,
        ),
      );
      processedLines.add(line.copyWith(serialNumbers: movedSerials));
    }

    return StockMutationOutcome.success(
      StockMutationResult(
        products: updatedProducts,
        lines: processedLines,
        movements: movements,
      ),
    );
  }

  static StockMutationOutcome applySortieReturn({
    required List<Product> products,
    required BusinessDocument document,
    required Map<String, int> returnedQuantities,
    required DateTime date,
  }) {
    final targetWarehouseId = document.metadata['targetWarehouseId'] as String?;
    if (targetWarehouseId == null || targetWarehouseId.isEmpty) {
      return const StockMutationOutcome.failure(
        'Dépôt mobile non défini dans le document.',
      );
    }

    final updatedProducts = List<Product>.from(products);
    final movements = <StockMovement>[];

    for (final entry in returnedQuantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;
      if (quantity <= 0) continue;

      final product = _productById(updatedProducts, productId);
      if (!product.stockTracked) continue;

      if (product.stockIn(targetWarehouseId) < quantity) {
        return StockMutationOutcome.failure(
          'Stock insuffisant pour ${product.name} dans le dépôt mobile.',
        );
      }

      final stock = Map<String, int>.from(product.stockByWarehouse);
      final serials = _copySerials(product.serialsByWarehouse);

      stock[targetWarehouseId] = (stock[targetWarehouseId] ?? 0) - quantity;
      stock[document.warehouseId] =
          (stock[document.warehouseId] ?? 0) + quantity;

      // Simplified serial handling for returns: move first available
      var movedSerials = <String>[];
      if (product.serialTracked) {
        final available = serials[targetWarehouseId] ?? <String>[];
        movedSerials = available.take(quantity).toList();
        serials[targetWarehouseId] = available
            .where((serial) => !movedSerials.contains(serial))
            .toList();
        serials[document.warehouseId] = [
          ...(serials[document.warehouseId] ?? const <String>[]),
          ...movedSerials,
        ];
      }

      _replaceProduct(
        updatedProducts,
        product.copyWith(stockByWarehouse: stock, serialsByWarehouse: serials),
      );

      movements.add(
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.outbound,
          quantity: quantity,
          warehouseId: targetWarehouseId,
          serialNumbers: movedSerials,
          reason: 'Retour sortie camion',
        ),
      );
      movements.add(
        StockMovement(
          date: date,
          productId: product.id,
          productName: product.name,
          documentNumber: document.number,
          sourceDocumentId: document.id,
          direction: StockDirection.inbound,
          quantity: quantity,
          warehouseId: document.warehouseId,
          serialNumbers: movedSerials,
          reason: 'Retour sortie camion',
        ),
      );
    }

    return StockMutationOutcome.success(
      StockMutationResult(
        products: updatedProducts,
        lines: document.lines, // Lines stay same, metadata tracks returns
        movements: movements,
      ),
    );
  }

  static Product _productById(List<Product> products, String id) =>
      products.firstWhere((product) => product.id == id);

  static void _replaceProduct(List<Product> products, Product updated) {
    final index = products.indexWhere((product) => product.id == updated.id);
    if (index >= 0) {
      products[index] = updated;
    }
  }

  static Map<String, List<String>> _copySerials(
    Map<String, List<String>> serialsByWarehouse,
  ) {
    return serialsByWarehouse.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
  }
}

extension on BusinessDocument {
  BusinessDocument copyForStockReversal({
    required DocumentType type,
    required DateTime date,
  }) {
    return BusinessDocument(
      id: 'reverse-$id',
      type: type,
      number: 'ANN-$number',
      status: DocumentStatus.validated,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerTaxId: partnerTaxId,
      partnerAddress: partnerAddress,
      date: date,
      lines: lines,
      warehouseId: warehouseId,
      companySnapshot: companySnapshot,
    );
  }
}
