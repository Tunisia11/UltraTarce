import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';
import '../../../domain/services/stock_mutation_service.dart';

class StockState {
  const StockState({
    required this.products,
    required this.movements,
    required this.lowStockProducts,
  });

  factory StockState.initial() =>
      const StockState(products: [], movements: [], lowStockProducts: []);

  final List<Product> products;
  final List<StockMovement> movements;
  final List<Product> lowStockProducts;
}

class StockCubit extends Cubit<StockState> {
  StockCubit(this._stockRepository, this._auditRepository)
    : super(StockState.initial());

  final StockRepository _stockRepository;
  final AuditRepository _auditRepository;

  void loadStockOverview() {
    emit(
      StockState(
        products: _stockRepository.products,
        movements: _stockRepository.movements,
        lowStockProducts: getLowStockProducts(),
      ),
    );
  }

  void loadMovements() => loadStockOverview();

  AppSnapshot adjustStock({
    required String productId,
    required String warehouseId,
    required StockDirection direction,
    required int quantity,
    required List<String> serialNumbers,
    required String movementNumber,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
    String? auditTarget,
    String? auditDetail,
  }) {
    final outcome = StockMutationService.applyAdjustment(
      products: _stockRepository.products,
      productId: productId,
      warehouseId: warehouseId,
      direction: direction,
      quantity: quantity,
      serialNumbers: serialNumbers,
      movementNumber: movementNumber,
      date: date,
      serialGenerator: serialGenerator,
    );
    if (!outcome.isSuccess) throw StateError(outcome.errorMessage!);
    _stockRepository.applyStockMutation(
      outcome.result!,
      status: 'Stock ajusté.',
    );
    final snapshot = _appendAudit(
      action: 'Ajustement stock',
      target: auditTarget ?? productId,
      detail: auditDetail ?? '${direction.name} $quantity',
    );
    loadStockOverview();
    return snapshot;
  }

  AppSnapshot transferStock({
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    required List<String> serialNumbers,
    required String movementNumber,
    required DateTime date,
    required String detail,
  }) {
    final outcome = StockMutationService.applyTransfer(
      products: _stockRepository.products,
      productId: productId,
      fromWarehouseId: fromWarehouseId,
      toWarehouseId: toWarehouseId,
      quantity: quantity,
      serialNumbers: serialNumbers,
      movementNumber: movementNumber,
      date: date,
    );
    if (!outcome.isSuccess) throw StateError(outcome.errorMessage!);
    _stockRepository.applyStockMutation(
      outcome.result!,
      status: 'Transfert stock sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Transfert stock',
      target: productId,
      detail: detail,
    );
    loadStockOverview();
    return snapshot;
  }

  AppSnapshot createStockEntry({
    required BusinessDocument document,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
  }) {
    final result = StockMutationService.applyInboundDocument(
      products: _stockRepository.products,
      document: document,
      date: date,
      serialGenerator: serialGenerator,
    );
    _stockRepository.applyStockMutation(
      result,
      status: '${document.number} reçu: stock augmenté.',
    );
    final snapshot = _appendAudit(
      action: 'Réception stock',
      target: document.number,
      detail: '${document.lines.length} ligne(s).',
    );
    loadStockOverview();
    return snapshot;
  }

  StockMutationResult decreaseStockForDocument({
    required BusinessDocument document,
    required DateTime date,
  }) {
    final result = StockMutationService.applyOutboundDocument(
      products: _stockRepository.products,
      document: document,
      date: date,
    );
    _stockRepository.applyStockMutation(
      result,
      status: '${document.number}: stock diminué.',
    );
    loadStockOverview();
    return result;
  }

  StockMutationResult increaseStockForDocument({
    required BusinessDocument document,
    required DateTime date,
    required String Function(String sku, int index) serialGenerator,
  }) {
    final result = StockMutationService.applyInboundDocument(
      products: _stockRepository.products,
      document: document,
      date: date,
      serialGenerator: serialGenerator,
    );
    _stockRepository.applyStockMutation(
      result,
      status: '${document.number}: stock augmenté.',
    );
    loadStockOverview();
    return result;
  }

  StockMutationResult transferStockForDocument({
    required BusinessDocument document,
    required DateTime date,
  }) {
    final outcome = StockMutationService.applyTransferDocument(
      products: _stockRepository.products,
      document: document,
      date: date,
    );
    if (!outcome.isSuccess) throw StateError(outcome.errorMessage!);
    _stockRepository.applyStockMutation(
      outcome.result!,
      status: '${document.number}: stock transféré.',
    );
    loadStockOverview();
    return outcome.result!;
  }

  StockMutationResult applySortieReturn({
    required List<Product> products,
    required BusinessDocument document,
    required Map<String, int> returnedQuantities,
    required DateTime date,
  }) {
    final outcome = StockMutationService.applySortieReturn(
      products: products,
      document: document,
      returnedQuantities: returnedQuantities,
      date: date,
    );
    if (!outcome.isSuccess) throw StateError(outcome.errorMessage!);
    _stockRepository.applyStockMutation(
      outcome.result!,
      status: '${document.number}: retour stock effectué.',
    );
    loadStockOverview();
    return outcome.result!;
  }

  StockMutationOutcome reverseDocumentStock({
    required BusinessDocument document,
    required DateTime date,
    required String Function(String warehouseId) warehouseNameById,
    required String Function(String sku, int index) serialGenerator,
  }) {
    final outcome = StockMutationService.reverseDocument(
      products: _stockRepository.products,
      document: document,
      date: date,
      warehouseNameById: warehouseNameById,
      serialGenerator: serialGenerator,
    );
    if (outcome.isSuccess) {
      _stockRepository.applyStockMutation(
        outcome.result!,
        status: '${document.number}: stock corrigé.',
      );
      loadStockOverview();
    }
    return outcome;
  }

  List<Product> getLowStockProducts() {
    return StockMutationService.lowStockProducts(_stockRepository.products);
  }

  List<StockMovement> getProductMovements(String productId) {
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
