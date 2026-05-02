import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/app_result.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';
import '../../../domain/services/document_lifecycle_service.dart';
import '../../../domain/services/payment_service.dart';
import '../../../domain/services/pricing_service.dart';
import '../../../domain/services/stock_mutation_service.dart';
import '../../../domain/services/tax_service.dart';

class SalesState {
  const SalesState({
    required this.documentType,
    required this.lines,
    this.selectedClientId = '',
    this.selectedWarehouseId = '',
    this.discountRate = 0,
    this.createdDocument,
    this.lastMutationResult,
  });

  factory SalesState.initial() =>
      const SalesState(documentType: DocumentType.facture, lines: []);

  final DocumentType documentType;
  final List<DocumentLine> lines;
  final String selectedClientId;
  final String selectedWarehouseId;
  final double discountRate;
  final BusinessDocument? createdDocument;
  final AppResult<AppSnapshot>? lastMutationResult;

  double get totalHt => PricingService.documentTotalHt(lines);
  double get totalTva => PricingService.documentTotalTva(lines);

  double netToPay(CompanyProfile company) {
    return TaxService.fiscalTotals(
      lines: lines,
      applyTimbreFiscal:
          documentType == DocumentType.facture && company.timbreFiscalEnabled,
      timbreFiscalAmount: company.timbreFiscalAmount,
    ).netToPay;
  }

  SalesState copyWith({
    DocumentType? documentType,
    List<DocumentLine>? lines,
    String? selectedClientId,
    String? selectedWarehouseId,
    double? discountRate,
    BusinessDocument? createdDocument,
    bool clearCreatedDocument = false,
    AppResult<AppSnapshot>? lastMutationResult,
  }) {
    return SalesState(
      documentType: documentType ?? this.documentType,
      lines: lines ?? this.lines,
      selectedClientId: selectedClientId ?? this.selectedClientId,
      selectedWarehouseId: selectedWarehouseId ?? this.selectedWarehouseId,
      discountRate: discountRate ?? this.discountRate,
      createdDocument: clearCreatedDocument
          ? null
          : createdDocument ?? this.createdDocument,
      lastMutationResult: lastMutationResult ?? this.lastMutationResult,
    );
  }
}

class SalesCubit extends Cubit<SalesState> {
  SalesCubit(
    this._documentRepository,
    this._stockRepository,
    this._auditRepository,
  ) : super(SalesState.initial());

  final DocumentRepository _documentRepository;
  final StockRepository _stockRepository;
  final AuditRepository _auditRepository;

  String nextNumber(DocumentType type) => _documentRepository.nextNumber(type);

  void startSale({DocumentType type = DocumentType.facture}) {
    emit(SalesState.initial().copyWith(documentType: type));
  }

  void selectClient(String clientId) {
    emit(state.copyWith(selectedClientId: clientId));
  }

  void applyDiscount(double discountRate) {
    emit(state.copyWith(discountRate: discountRate.clamp(0, 100).toDouble()));
  }

  void selectWarehouse(String warehouseId) {
    emit(state.copyWith(selectedWarehouseId: warehouseId));
  }

  void addLine(Product product, {required int quantity, double? discountRate}) {
    final line = DocumentLine(
      productId: product.id,
      label: product.name,
      sku: product.sku,
      quantity: quantity,
      unitHt: product.saleHt,
      tvaRate: product.tvaRate,
      discountRate: (discountRate ?? state.discountRate)
          .clamp(0, 100)
          .toDouble(),
    );
    final lines = List<DocumentLine>.from(state.lines);
    final index = lines.indexWhere((item) => item.productId == product.id);
    if (index >= 0) {
      final existing = lines[index];
      lines[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      lines.add(line);
    }
    emit(state.copyWith(lines: lines, clearCreatedDocument: true));
  }

  void updateQuantity(String productId, int quantity) {
    final lines = List<DocumentLine>.from(state.lines);
    final index = lines.indexWhere((line) => line.productId == productId);
    if (index < 0) return;
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: quantity);
    }
    emit(state.copyWith(lines: lines, clearCreatedDocument: true));
  }

  void removeLine(String productId) {
    emit(
      state.copyWith(
        lines: state.lines
            .where((line) => line.productId != productId)
            .toList(),
        clearCreatedDocument: true,
      ),
    );
  }

  AppSnapshot createSale({
    required String id,
    required String number,
    required Partner client,
    required CompanyProfile company,
    required DateTime date,
    required String warehouseId,
  }) {
    return saveSaleDocument(
      id: id,
      number: number,
      type: state.documentType,
      client: client,
      company: company,
      date: date,
      lines: List<DocumentLine>.from(state.lines),
      warehouseId: warehouseId,
    );
  }

  Future<AppResult<AppSnapshot>> createSaleResult({
    required String id,
    required String number,
    required Partner client,
    required CompanyProfile company,
    required DateTime date,
    required String warehouseId,
  }) async {
    try {
      final snapshot = createSale(
        id: id,
        number: number,
        client: client,
        company: company,
        date: date,
        warehouseId: warehouseId,
      );
      final persistence = await _documentRepository.flushPendingWritesResult();
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
          code: 'sale_create_failed',
          message: 'Impossible de sauvegarder la vente.',
          cause: error,
        ),
      );
      emit(state.copyWith(lastMutationResult: result));
      return result;
    }
  }

  AppSnapshot saveSaleDocument({
    required String id,
    required String number,
    required DocumentType type,
    required Partner client,
    required CompanyProfile company,
    required DateTime date,
    required List<DocumentLine> lines,
    required String warehouseId,
    Map<String, dynamic> metadata = const {},
    bool isUpdate = false,
  }) {
    final document = DocumentLifecycleService.buildSalesDocument(
      id: id,
      type: type,
      number: number,
      client: client,
      date: date,
      lines: List<DocumentLine>.from(lines),
      warehouseId: warehouseId,
      company: company,
      applyTimbreFiscal:
          type == DocumentType.facture && company.timbreFiscalEnabled,
      timbreFiscalAmount: company.timbreFiscalAmount,
      metadata: metadata,
    );
    _documentRepository.upsert(
      document,
      status: '${document.number} sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: isUpdate ? 'Modification vente' : 'Création vente',
      target: document.number,
      detail:
          'Vente ${isUpdate ? 'mise à jour' : 'créée'} pour ${document.partnerName} avec ${document.lines.length} ligne(s).',
    );
    emit(state.copyWith(lines: const [], createdDocument: document));
    return snapshot;
  }

  AppSnapshot addPayment({
    required BusinessDocument document,
    required Iterable<BusinessDocument> documents,
    required PaymentEntry payment,
    required String Function(double value) formatMoney,
  }) {
    final updated = PaymentService.recordPayment(
      documents,
      document,
      payment,
      formatMoney: formatMoney,
    );
    _documentRepository.upsert(updated, status: 'Paiement sauvegardé.');
    return _appendAudit(
      action: 'Paiement',
      target: document.number,
      detail: '${payment.method.label} · ${formatMoney(payment.amount)}.',
    );
  }

  Future<AppResult<AppSnapshot>> addPaymentResult({
    required BusinessDocument document,
    required Iterable<BusinessDocument> documents,
    required PaymentEntry payment,
    required String Function(double value) formatMoney,
  }) async {
    try {
      final snapshot = addPayment(
        document: document,
        documents: documents,
        payment: payment,
        formatMoney: formatMoney,
      );
      final persistence = await _documentRepository.flushPendingWritesResult();
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
          code: 'payment_add_failed',
          message: 'Impossible de sauvegarder le paiement.',
          cause: error,
        ),
      );
      emit(state.copyWith(lastMutationResult: result));
      return result;
    }
  }

  void clearSale() {
    emit(SalesState.initial());
  }

  StockMutationResult decreaseStockForSale(BusinessDocument document) {
    return StockMutationService.applyOutboundDocument(
      products: _stockRepository.products,
      document: document,
      date: DateTime.now(),
    );
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
