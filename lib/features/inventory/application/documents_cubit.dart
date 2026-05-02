import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/app_result.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';
import '../../../domain/services/document_lifecycle_service.dart';
import '../../../domain/services/payment_service.dart';
import '../../../domain/services/pricing_service.dart';
import '../../../domain/services/return_service.dart';

class DocumentsState {
  const DocumentsState({
    required this.documents,
    required this.filteredDocuments,
    this.lastMutationResult,
  });

  factory DocumentsState.initial() =>
      const DocumentsState(documents: [], filteredDocuments: []);

  final List<BusinessDocument> documents;
  final List<BusinessDocument> filteredDocuments;
  final AppResult<AppSnapshot>? lastMutationResult;

  DocumentsState copyWith({
    List<BusinessDocument>? documents,
    List<BusinessDocument>? filteredDocuments,
    AppResult<AppSnapshot>? lastMutationResult,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      lastMutationResult: lastMutationResult ?? this.lastMutationResult,
    );
  }
}

class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit(this._documentRepository, this._auditRepository)
    : super(DocumentsState.initial());

  final DocumentRepository _documentRepository;
  final AuditRepository _auditRepository;

  String nextNumber(DocumentType type) => _documentRepository.nextNumber(type);

  void loadDocuments() {
    final documents = _documentRepository.getAll();
    emit(DocumentsState(documents: documents, filteredDocuments: documents));
  }

  void filterDocuments({
    DocumentType? type,
    DocumentStatus? status,
    String query = '',
  }) {
    emit(
      DocumentsState(
        documents: _documentRepository.getAll(),
        filteredDocuments: _documentRepository.filter(
          type: type,
          status: status,
          query: query,
        ),
      ),
    );
  }

  AppSnapshot createDevis(BusinessDocument document) =>
      _createTypedDocument(document, DocumentType.devis);

  AppSnapshot createBonLivraison(BusinessDocument document) =>
      _createTypedDocument(document, DocumentType.bl);

  AppSnapshot createFacture(BusinessDocument document) =>
      _createTypedDocument(document, DocumentType.facture);

  AppSnapshot _createTypedDocument(
    BusinessDocument document,
    DocumentType type,
  ) {
    _documentRepository.upsert(
      document,
      status: '${document.number} sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Création document',
      target: document.number,
      detail: type.label,
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot createSupplierDocument({
    required BusinessDocument document,
    required bool receiveNow,
  }) {
    _documentRepository.upsert(
      document,
      status: '${document.number} sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: receiveNow ? 'Réception fournisseur' : 'Commande fournisseur',
      target: document.number,
      detail:
          '${document.partnerName}: ${document.lines.first.quantity} x ${document.lines.first.label}.',
    );
    loadDocuments();
    return snapshot;
  }

  BusinessDocument buildSupplierPurchaseDocument({
    required String id,
    required DocumentType type,
    required String number,
    required Partner supplier,
    required DateTime date,
    required String warehouseId,
    required CompanyProfile company,
    required DocumentLine line,
    required String note,
  }) {
    return DocumentLifecycleService.buildSupplierDocument(
      id: id,
      type: type,
      number: number,
      supplier: supplier,
      date: date,
      warehouseId: warehouseId,
      company: company,
      line: line,
      note: note,
    );
  }

  AppSnapshot validateDocument({
    required BusinessDocument document,
    required List<DocumentLine> lines,
    required bool stockApplied,
    required String Function(double value) formatMoney,
  }) {
    final validated = DocumentLifecycleService.markValidated(
      document,
      lines: lines,
      stockApplied: stockApplied,
    );
    _documentRepository.upsert(
      validated,
      status: '${document.number} validé et sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Validation',
      target: document.number,
      detail:
          '${document.type.label} validé et verrouillé. Net ${formatMoney(PricingService.documentNetToPay(lines: lines, applyTimbreFiscal: document.applyTimbreFiscal, timbreFiscalAmount: document.timbreFiscalAmount))}.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot convertDevisToBl({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
  }) {
    final document = DocumentLifecycleService.buildBlFromQuote(
      source: source,
      id: id,
      number: number,
      date: date,
    );
    _documentRepository.upsert(
      document,
      status: '${document.number} sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Conversion',
      target: document.number,
      detail: '${source.number} converti en bon de livraison.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot convertBlToFacture({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
    required bool applyTimbreFiscal,
    required double timbreFiscalAmount,
  }) {
    final invoice = DocumentLifecycleService.buildInvoiceFromBl(
      source: source,
      id: id,
      number: number,
      date: date,
      applyTimbreFiscal: applyTimbreFiscal,
      timbreFiscalAmount: timbreFiscalAmount,
    );
    _documentRepository.upsert(
      invoice,
      status: '${invoice.number} sauvegardée.',
    );
    final snapshot = _appendAudit(
      action: 'Facturation',
      target: invoice.number,
      detail: '${source.number} converti en facture sans mouvement de stock.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot createAvoir({
    required Iterable<BusinessDocument> documents,
    required BusinessDocument invoice,
    required List<DocumentLine> selectedLines,
    required String id,
    required String number,
    required DateTime date,
    required String note,
  }) {
    final creditNote = ReturnService.buildCreditNoteFromInvoice(
      documents: documents,
      invoice: invoice,
      selectedLines: selectedLines,
      id: id,
      number: number,
      date: date,
      note: note,
    );
    _documentRepository.upsert(
      creditNote,
      status: '${creditNote.number} sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Création avoir',
      target: creditNote.number,
      detail: 'Avoir préparé depuis ${invoice.number}.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot registerSortieReturn({
    required BusinessDocument document,
    required Map<String, int> returnedQuantities,
    required DateTime date,
    String? note,
  }) {
    final updated = ReturnService.registerSortieReturn(
      document: document,
      returnedQuantities: returnedQuantities,
      date: date,
      note: note,
    );
    _documentRepository.upsert(
      updated,
      status: '${document.number}: retour enregistré.',
    );
    final count = returnedQuantities.values.fold(0, (sum, q) => sum + q);
    final snapshot = _appendAudit(
      action: 'Retour sortie',
      target: document.number,
      detail: '$count produit(s) réintégrés au dépôt.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot closeSortie({
    required BusinessDocument document,
    required DateTime date,
  }) {
    final updated = ReturnService.closeSortie(document: document, date: date);
    _documentRepository.upsert(updated, status: '${document.number} clôturé.');

    // Calculate total delivered (total sortie - total returned)
    final returns = updated.returnedQuantities;
    var totalDelivered = 0;
    for (final line in updated.lines) {
      final returned = returns[line.productId] ?? 0;
      totalDelivered += (line.quantity - returned);
    }

    final snapshot = _appendAudit(
      action: 'Clôture sortie',
      target: document.number,
      detail: '$totalDelivered produits vendus/livrés.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot cancelDocument(BusinessDocument document) {
    final canceled = DocumentLifecycleService.markCanceled(document);
    _documentRepository.upsert(
      canceled,
      status: '${document.number} annulé et sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Annulation',
      target: document.number,
      detail: '${document.type.label} annulé avec stock cohérent.',
    );
    loadDocuments();
    return snapshot;
  }

  AppSnapshot addPayment({
    required BusinessDocument document,
    required Iterable<BusinessDocument> documents,
    required PaymentEntry payment,
    required String Function(double value) formatMoney,
    String? auditAction,
    String? auditDetail,
  }) {
    final updated = PaymentService.recordPayment(
      documents,
      document,
      payment,
      formatMoney: formatMoney,
    );
    _documentRepository.upsert(updated, status: 'Paiement sauvegardé.');
    final snapshot = _appendAudit(
      action: auditAction ?? 'Paiement',
      target: document.number,
      detail:
          auditDetail ??
          '${payment.method.label} · ${formatMoney(payment.amount)}.',
    );
    loadDocuments();
    return snapshot;
  }

  Future<AppResult<AppSnapshot>> addPaymentResult({
    required BusinessDocument document,
    required Iterable<BusinessDocument> documents,
    required PaymentEntry payment,
    required String Function(double value) formatMoney,
    String? auditAction,
    String? auditDetail,
  }) async {
    try {
      final snapshot = addPayment(
        document: document,
        documents: documents,
        payment: payment,
        formatMoney: formatMoney,
        auditAction: auditAction,
        auditDetail: auditDetail,
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
          code: 'document_payment_failed',
          message: 'Impossible de sauvegarder le paiement.',
          cause: error,
        ),
      );
      emit(state.copyWith(lastMutationResult: result));
      return result;
    }
  }

  AppSnapshot markAsPaid({
    required BusinessDocument document,
    required Iterable<BusinessDocument> documents,
    required String paymentId,
    required DateTime date,
    required String Function(double value) formatMoney,
  }) {
    final amount = PaymentService.invoiceRemainingDue(documents, document);
    return addPayment(
      document: document,
      documents: documents,
      payment: PaymentEntry(
        id: paymentId,
        date: date,
        amount: amount,
        method: PaymentMethod.cash,
      ),
      formatMoney: formatMoney,
    );
  }

  AppSnapshot convertSupplierOrderToStockEntry({
    required BusinessDocument source,
    required String id,
    required String number,
    required DateTime date,
  }) {
    final entry = DocumentLifecycleService.buildStockEntryFromSupplierOrder(
      source: source,
      id: id,
      number: number,
      date: date,
    );
    _documentRepository.upsert(entry, status: '${entry.number} sauvegardé.');
    final snapshot = _appendAudit(
      action: 'Réception fournisseur',
      target: entry.number,
      detail: '${source.number} converti en bon d’entrée.',
    );
    loadDocuments();
    return snapshot;
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
