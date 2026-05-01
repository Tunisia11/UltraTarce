import 'dart:convert';

import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import '../../core/result/app_result.dart';
import '../../domain/services/sequence_service.dart';
import '../local/database/drift_snapshot_store.dart';
import '../local/database/mappers/document_mapper.dart';
import 'app_repository.dart';

class DocumentRepository {
  DocumentRepository(this._appRepository);

  final AppRepository _appRepository;

  List<BusinessDocument> getAll() =>
      List<BusinessDocument>.from(_appRepository.snapshot.documents);

  Future<AppResult<void>> flushPendingWritesResult() {
    return _appRepository.flushPendingMutationResult();
  }

  List<BusinessDocument> filter({
    DocumentType? type,
    DocumentStatus? status,
    String query = '',
  }) {
    final normalized = query.trim().toLowerCase();
    return getAll()
        .where((document) => type == null || document.type == type)
        .where((document) => status == null || document.status == status)
        .where(
          (document) =>
              normalized.isEmpty ||
              document.number.toLowerCase().contains(normalized) ||
              document.partnerName.toLowerCase().contains(normalized),
        )
        .toList();
  }

  String nextNumber(DocumentType type) {
    final sequences = Map<DocumentType, int>.from(
      _appRepository.snapshot.sequences,
    );
    final number = SequenceService.consumeNextNumber(
      sequences: sequences,
      type: type,
    );
    _saveSnapshot(
      _appRepository.snapshot,
      sequences: sequences,
      status: 'Séquence ${type.label} mise à jour.',
    );
    return number;
  }

  AppSnapshot saveAll(
    List<BusinessDocument> documents, {
    Map<DocumentType, int>? sequences,
    required String status,
  }) {
    return _saveSnapshot(
      _appRepository.snapshot,
      documents: documents,
      sequences: sequences,
      status: status,
    );
  }

  AppSnapshot upsert(BusinessDocument document, {required String status}) {
    final previous = getAll();
    final oldDocument = _documentById(previous, document.id);
    final documents = getAll();
    final index = documents.indexWhere((item) => item.id == document.id);
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.insert(0, document);
    }
    return _saveSnapshot(
      _appRepository.snapshot,
      documents: documents,
      status: status,
      singleDocument: document,
      previousDocument: oldDocument,
    );
  }

  AppSnapshot _saveSnapshot(
    AppSnapshot snapshot, {
    List<BusinessDocument>? documents,
    Map<DocumentType, int>? sequences,
    BusinessDocument? singleDocument,
    BusinessDocument? previousDocument,
    required String status,
  }) {
    final updatedDocuments = documents ?? snapshot.documents;
    final updatedSequences = sequences ?? snapshot.sequences;
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: snapshot.company,
        warehouses: snapshot.warehouses,
        categories: snapshot.categories,
        products: snapshot.products,
        partners: snapshot.partners,
        documents: updatedDocuments,
        movements: snapshot.movements,
        sequences: updatedSequences,
        auditEvents: snapshot.auditEvents,
      ),
      status: status,
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        if (singleDocument != null) {
          if (_isSinglePaymentAppend(previousDocument, singleDocument)) {
            final previousIds = previousDocument!.payments
                .map((payment) => payment.id)
                .toSet();
            final payment = singleDocument.payments.firstWhere(
              (entry) => !previousIds.contains(entry.id),
            );
            await database.transaction(() async {
              await database.documentDao.upsertDocumentRow(
                DocumentMapper.toDocumentCompanion(
                  singleDocument,
                  tenantId: tenantId,
                ),
              );
              await database.documentDao.addPayment(
                DocumentMapper.paymentToCompanion(
                  payment,
                  documentId: singleDocument.id,
                  tenantId: tenantId,
                ),
              );
            });
          } else {
            await database.documentDao.upsertDocumentWithLines(
              document: DocumentMapper.toDocumentCompanion(
                singleDocument,
                tenantId: tenantId,
              ),
              lines: DocumentMapper.toLineCompanions(
                singleDocument,
                tenantId: tenantId,
              ),
              payments: DocumentMapper.toPaymentCompanions(
                singleDocument,
                tenantId: tenantId,
              ),
            );
          }
        } else if (documents != null) {
          final previousIds = snapshot.documents
              .map((document) => document.id)
              .toSet();
          final nextIds = documents.map((document) => document.id).toSet();
          await database.transaction(() async {
            for (final document in documents) {
              await database.documentDao.upsertDocumentWithLines(
                document: DocumentMapper.toDocumentCompanion(
                  document,
                  tenantId: tenantId,
                ),
                lines: DocumentMapper.toLineCompanions(
                  document,
                  tenantId: tenantId,
                ),
                payments: DocumentMapper.toPaymentCompanions(
                  document,
                  tenantId: tenantId,
                ),
              );
            }
            for (final deletedId in previousIds.difference(nextIds)) {
              await database.documentDao.deleteDocument(
                deletedId,
                tenantId: tenantId,
              );
            }
          });
        }
        if (sequences != null) {
          await database.settingsDao.setSetting(
            DriftSnapshotStore.sequencesSettingKey,
            jsonEncode(
              sequences.map((type, value) => MapEntry(type.name, value)),
            ),
            tenantId: tenantId,
          );
        }
      },
    );
  }

  bool _isSinglePaymentAppend(
    BusinessDocument? previous,
    BusinessDocument document,
  ) {
    if (previous == null) return false;
    if (previous.payments.length + 1 != document.payments.length) return false;
    if (jsonEncode(previous.lines.map((line) => line.toJson()).toList()) !=
        jsonEncode(document.lines.map((line) => line.toJson()).toList())) {
      return false;
    }
    final previousIds = previous.payments.map((payment) => payment.id).toSet();
    return document.payments
            .where((payment) => !previousIds.contains(payment.id))
            .length ==
        1;
  }

  BusinessDocument? _documentById(
    Iterable<BusinessDocument> documents,
    String id,
  ) {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }
}
