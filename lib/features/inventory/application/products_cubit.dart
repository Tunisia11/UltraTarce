import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/app_result.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';
import '../../../domain/services/stock_mutation_service.dart';

class ProductsState {
  const ProductsState({
    required this.products,
    required this.filteredProducts,
    required this.lowStockProducts,
    this.query = '',
    this.lastMutationResult,
  });

  factory ProductsState.initial() => const ProductsState(
    products: [],
    filteredProducts: [],
    lowStockProducts: [],
  );

  final List<Product> products;
  final List<Product> filteredProducts;
  final List<Product> lowStockProducts;
  final String query;
  final AppResult<AppSnapshot>? lastMutationResult;

  ProductsState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    List<Product>? lowStockProducts,
    String? query,
    AppResult<AppSnapshot>? lastMutationResult,
  }) {
    return ProductsState(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      query: query ?? this.query,
      lastMutationResult: lastMutationResult ?? this.lastMutationResult,
    );
  }
}

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(
    this._productRepository,
    this._stockRepository,
    this._auditRepository,
  ) : super(ProductsState.initial());

  final ProductRepository _productRepository;
  final StockRepository _stockRepository;
  final AuditRepository _auditRepository;

  void loadProducts() {
    final products = _productRepository.getAll();
    emit(
      ProductsState(
        products: products,
        filteredProducts: products,
        lowStockProducts: StockMutationService.lowStockProducts(products),
      ),
    );
  }

  void searchProducts(String query) {
    final products = _productRepository.getAll();
    emit(
      ProductsState(
        products: products,
        filteredProducts: _productRepository.search(query),
        lowStockProducts: StockMutationService.lowStockProducts(products),
        query: query,
      ),
    );
  }

  AppSnapshot createProduct(
    Product product, {
    String? initialWarehouseId,
    int initialStockQuantity = 0,
    String? movementNumber,
    DateTime? date,
    String Function(String sku, int index)? serialGenerator,
  }) {
    var products = List<Product>.from(_productRepository.getAll());
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }

    StockMutationResult? initialStock;
    if (initialStockQuantity > 0) {
      final outcome = StockMutationService.applyInitialStock(
        products: products,
        productId: product.id,
        warehouseId: initialWarehouseId!,
        quantity: initialStockQuantity,
        movementNumber: movementNumber!,
        date: date ?? DateTime.now(),
        serialGenerator: serialGenerator!,
      );
      if (!outcome.isSuccess) {
        throw StateError(outcome.errorMessage!);
      }
      initialStock = outcome.result!;
      products = initialStock.products;
    }

    var snapshot = _productRepository.saveAll(
      products,
      status: 'Produit sauvegardé.',
    );
    if (initialStock != null) {
      snapshot = _stockRepository.applyStockMutation(
        initialStock,
        status: 'Stock initial sauvegardé.',
      );
    }
    snapshot = _appendAudit(
      action: 'Création produit',
      target: product.sku,
      detail: initialStockQuantity > 0
          ? '${product.name} · stock initial $initialStockQuantity'
          : product.name,
    );
    loadProducts();
    return snapshot;
  }

  Future<AppResult<AppSnapshot>> createProductResult(
    Product product, {
    String? initialWarehouseId,
    int initialStockQuantity = 0,
    String? movementNumber,
    DateTime? date,
    String Function(String sku, int index)? serialGenerator,
  }) async {
    try {
      final snapshot = createProduct(
        product,
        initialWarehouseId: initialWarehouseId,
        initialStockQuantity: initialStockQuantity,
        movementNumber: movementNumber,
        date: date,
        serialGenerator: serialGenerator,
      );
      final persistence = await _productRepository.flushPendingWritesResult();
      if (persistence is AppFailure<void>) {
        final result = AppFailure<AppSnapshot>(persistence.error);
        emit(state.copyWith(lastMutationResult: result));
        return result;
      }
      final result = AppSuccess(snapshot);
      emit(state.copyWith(lastMutationResult: result));
      return result;
    } catch (error) {
      final result = AppFailure<AppSnapshot>(
        AppError(
          code: 'product_create_failed',
          message: 'Impossible de sauvegarder le produit.',
          cause: error,
        ),
      );
      emit(state.copyWith(lastMutationResult: result));
      return result;
    }
  }

  AppSnapshot updateProduct(Product product) {
    _productRepository.upsert(product, status: 'Produit sauvegardé.');
    final snapshot = _appendAudit(
      action: 'Modification produit',
      target: product.sku,
      detail: product.name,
    );
    loadProducts();
    return snapshot;
  }

  AppSnapshot archiveProduct(Product product) {
    _productRepository.archive(product, status: 'Catalogue sauvegardé.');
    final snapshot = _appendAudit(
      action: 'Désactivation produit',
      target: product.sku,
      detail: product.name,
    );
    loadProducts();
    return snapshot;
  }

  AppSnapshot deleteOrArchiveProduct(Product product) {
    final used = _productRepository.isUsed(product.id);
    if (used) {
      _productRepository.archive(product, status: 'Catalogue sauvegardé.');
    } else {
      _productRepository.delete(product, status: 'Catalogue sauvegardé.');
    }
    final snapshot = _appendAudit(
      action: used ? 'Désactivation produit' : 'Suppression produit',
      target: product.sku,
      detail: product.name,
    );
    loadProducts();
    return snapshot;
  }

  AppSnapshot? createInitialStockIfNeeded({
    required Product product,
    required String warehouseId,
    required int quantity,
    required String movementNumber,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
  }) {
    if (quantity <= 0) return null;
    final outcome = StockMutationService.applyInitialStock(
      products: _stockRepository.products,
      productId: product.id,
      warehouseId: warehouseId,
      quantity: quantity,
      movementNumber: movementNumber,
      date: date,
      serialGenerator: serialGenerator,
    );
    if (!outcome.isSuccess) {
      throw StateError(outcome.errorMessage!);
    }
    _stockRepository.applyStockMutation(
      outcome.result!,
      status: 'Stock initial sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Stock initial',
      target: product.sku,
      detail: '${product.name} · stock initial $quantity',
    );
    loadProducts();
    return snapshot;
  }

  List<Product> getLowStockProducts() {
    return StockMutationService.lowStockProducts(_productRepository.getAll());
  }

  AppSnapshot adjustStock({
    required String productId,
    required String warehouseId,
    required int quantity,
    required StockDirection direction,
    String? reason,
    String? note,
    required String movementNumber,
    required String Function(String sku, int index) serialGenerator,
  }) {
    final outcome = StockMutationService.applyAdjustment(
      products: _productRepository.getAll(),
      productId: productId,
      warehouseId: warehouseId,
      direction: direction,
      quantity: quantity,
      serialNumbers: const [],
      movementNumber: movementNumber,
      date: DateTime.now(),
      serialGenerator: serialGenerator,
      reason: reason,
      note: note,
    );
    if (!outcome.isSuccess) {
      throw StateError(outcome.errorMessage!);
    }

    final snapshot = _stockRepository.applyStockMutation(
      outcome.result!,
      status: 'Mouvement de stock enregistré.',
    );
    final product = outcome.result!.products.firstWhere(
      (p) => p.id == productId,
    );
    _appendAudit(
      action: 'Mouvement stock',
      target: product.sku,
      detail:
          '${product.name} · ${direction == StockDirection.inbound ? 'Entrée' : 'Sortie'} $quantity · $reason',
    );
    loadProducts();
    return snapshot;
  }

  AppSnapshot transferStock({
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    String? reason,
    String? note,
    required String movementNumber,
  }) {
    final outcome = StockMutationService.applyTransfer(
      products: _productRepository.getAll(),
      productId: productId,
      fromWarehouseId: fromWarehouseId,
      toWarehouseId: toWarehouseId,
      quantity: quantity,
      serialNumbers: const [],
      movementNumber: movementNumber,
      date: DateTime.now(),
      reason: reason,
      note: note,
    );
    if (!outcome.isSuccess) {
      throw StateError(outcome.errorMessage!);
    }

    final snapshot = _stockRepository.applyStockMutation(
      outcome.result!,
      status: 'Transfert de stock enregistré.',
    );
    final product = outcome.result!.products.firstWhere(
      (p) => p.id == productId,
    );
    _appendAudit(
      action: 'Transfert stock',
      target: product.sku,
      detail:
          '${product.name} · $quantity de $fromWarehouseId vers $toWarehouseId',
    );
    loadProducts();
    return snapshot;
  }

  List<StockMovement> getMovementsForProduct(String productId) {
    return _stockRepository.movementsForProduct(productId);
  }

  AppSnapshot _appendAudit({
    required String action,
    required String target,
    required String detail,
  }) {
    return _auditRepository.saveAll(
      AuditService.append(
        events: _auditRepository.getAll(),
        action: action,
        target: target,
        detail: detail,
      ),
      status: 'Audit sauvegardé.',
    );
  }
}
