part of '../app_database.dart';

class DocumentBundle {
  const DocumentBundle({
    required this.document,
    required this.lines,
    required this.payments,
  });

  final DocumentRow document;
  final List<DocumentLineRow> lines;
  final List<PaymentRow> payments;
}

@DriftAccessor(tables: [Documents, DocumentLines, Payments])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Future<List<DocumentRow>> getDocuments({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(documents)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.issueDate)]))
        .get();
  }

  Stream<List<DocumentRow>> watchDocuments({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(documents)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.issueDate)]))
        .watch();
  }

  Future<DocumentBundle?> getDocumentWithLinesAndPayments(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rowId = TenantRowScope.rowId(tenantId, id);
    final document =
        await (select(documents)..where(
              (table) =>
                  table.id.equals(rowId) & table.tenantId.equals(tenantId),
            ))
            .getSingleOrNull();
    if (document == null) return null;
    final lines = await _linesForDocument(rowId, tenantId: tenantId).get();
    final documentPayments = await _paymentsForDocument(
      rowId,
      tenantId: tenantId,
    ).get();
    return DocumentBundle(
      document: document,
      lines: lines,
      payments: documentPayments,
    );
  }

  Future<void> upsertDocumentWithLines({
    required DocumentsCompanion document,
    required List<DocumentLinesCompanion> lines,
    required List<PaymentsCompanion> payments,
  }) async {
    await transaction(() async {
      await into(documents).insertOnConflictUpdate(document);
      await (delete(documentLines)..where(
            (table) =>
                table.documentId.equals(document.id.value) &
                table.tenantId.equals(document.tenantId.value),
          ))
          .go();
      await (delete(this.payments)..where(
            (table) =>
                table.documentId.equals(document.id.value) &
                table.tenantId.equals(document.tenantId.value),
          ))
          .go();
      await batch((batch) {
        batch.insertAll(documentLines, lines, mode: InsertMode.insertOrReplace);
        batch.insertAll(
          this.payments,
          payments,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> addPayment(PaymentsCompanion payment) {
    return into(payments).insertOnConflictUpdate(payment);
  }

  Future<void> upsertDocumentRow(DocumentsCompanion document) {
    return into(documents).insertOnConflictUpdate(document);
  }

  Future<void> updateDocumentStatus(
    String id,
    String status, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (update(documents)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .write(
          DocumentsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteDocument(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rowId = TenantRowScope.rowId(tenantId, id);
    await transaction(() async {
      await (delete(payments)..where(
            (table) =>
                table.documentId.equals(rowId) &
                table.tenantId.equals(tenantId),
          ))
          .go();
      await (delete(documentLines)..where(
            (table) =>
                table.documentId.equals(rowId) &
                table.tenantId.equals(tenantId),
          ))
          .go();
      await (delete(documents)..where(
            (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
          ))
          .go();
    });
  }

  Future<List<DocumentRow>> getDocumentsByType(
    String type, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(documents)
          ..where(
            (table) =>
                table.tenantId.equals(tenantId) & table.type.equals(type),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.issueDate)]))
        .get();
  }

  Future<List<DocumentRow>> getRecentDocuments(
    int limit, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(documents)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.issueDate)])
          ..limit(limit))
        .get();
  }

  Future<List<DocumentRow>> getUnpaidDocuments({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(documents)
          ..where(
            (table) =>
                table.tenantId.equals(tenantId) &
                table.remainingAmount.isBiggerThanValue(0),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.issueDate)]))
        .get();
  }

  SimpleSelectStatement<$DocumentLinesTable, DocumentLineRow> _linesForDocument(
    String documentId, {
    required String tenantId,
  }) {
    return select(documentLines)
      ..where(
        (table) =>
            table.tenantId.equals(tenantId) &
            table.documentId.equals(documentId),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);
  }

  SimpleSelectStatement<$PaymentsTable, PaymentRow> _paymentsForDocument(
    String documentId, {
    required String tenantId,
  }) {
    return select(payments)
      ..where(
        (table) =>
            table.tenantId.equals(tenantId) &
            table.documentId.equals(documentId),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.date)]);
  }
}
