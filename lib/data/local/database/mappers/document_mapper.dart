import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class DocumentMapper {
  static DocumentsCompanion toDocumentCompanion(
    BusinessDocument document, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return DocumentsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, document.id)),
      tenantId: Value(tenantId),
      type: Value(document.type.name),
      status: Value(document.status.name),
      number: Value(document.number),
      sequence: Value(_sequenceFromNumber(document.number)),
      partnerId: Value(TenantRowScope.rowId(tenantId, document.partnerId)),
      partnerName: Value(document.partnerName),
      partnerTaxId: Value(document.partnerTaxId),
      partnerAddress: Value(document.partnerAddress),
      issueDate: Value(document.date),
      warehouseId: Value(TenantRowScope.rowId(tenantId, document.warehouseId)),
      sourceNumber: Value(document.sourceNumber),
      notes: Value(document.note),
      stockApplied: Value(document.stockApplied),
      applyTimbreFiscal: Value(document.applyTimbreFiscal),
      subtotalHt: Value(document.totalHt),
      totalDiscount: Value(
        document.lines.fold<double>(
          0,
          (total, line) => total + line.discountAmount,
        ),
      ),
      totalTva: Value(document.totalTva),
      timbreFiscal: Value(document.timbreAmount),
      totalTtc: Value(document.totalTtc),
      paidAmount: Value(document.paidAmount),
      remainingAmount: Value(document.remainingAmount),
      metadataJson: Value(jsonEncode(document.metadata)),
      companySnapshotJson: Value(
        document.companySnapshot == null
            ? null
            : jsonEncode(document.companySnapshot!.toJson()),
      ),
      updatedAt: Value(now),
    );
  }

  static List<DocumentLinesCompanion> toLineCompanions(
    BusinessDocument document, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return [
      for (var index = 0; index < document.lines.length; index++)
        _lineToCompanion(document, document.lines[index], index, tenantId),
    ];
  }

  static List<PaymentsCompanion> toPaymentCompanions(
    BusinessDocument document, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return [
      for (final payment in document.payments)
        paymentToCompanion(
          payment,
          documentId: document.id,
          tenantId: tenantId,
        ),
    ];
  }

  static PaymentsCompanion paymentToCompanion(
    PaymentEntry payment, {
    required String documentId,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return PaymentsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, payment.id)),
      tenantId: Value(tenantId),
      documentId: Value(TenantRowScope.rowId(tenantId, documentId)),
      amount: Value(payment.amount),
      method: Value(payment.method.name),
      date: Value(payment.date),
      reference: Value(payment.reference),
      note: Value(payment.note),
      updatedAt: Value(now),
    );
  }

  static BusinessDocument fromRows({
    required DocumentRow document,
    required List<DocumentLineRow> lines,
    required List<PaymentRow> payments,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return BusinessDocument(
      id: TenantRowScope.domainId(tenantId, document.id),
      type: enumFromName(
        DocumentType.values,
        document.type,
        DocumentType.devis,
      ),
      number: document.number,
      status: enumFromName(
        DocumentStatus.values,
        document.status,
        DocumentStatus.draft,
      ),
      partnerId: TenantRowScope.domainId(tenantId, document.partnerId),
      partnerName: document.partnerName,
      partnerTaxId: document.partnerTaxId,
      partnerAddress: document.partnerAddress,
      date: document.issueDate,
      lines: lines.map((row) => _lineFromRow(row, tenantId)).toList(),
      warehouseId: TenantRowScope.domainId(tenantId, document.warehouseId),
      companySnapshot: _companySnapshotFromJson(document.companySnapshotJson),
      metadata: Map<String, dynamic>.from(
        jsonDecode(document.metadataJson) as Map? ?? const {},
      ),
      sourceNumber: document.sourceNumber,
      note: document.notes,
      stockApplied: document.stockApplied,
      applyTimbreFiscal: document.applyTimbreFiscal,
      timbreFiscalAmount: document.timbreFiscal,
      payments: payments.map((row) => _paymentFromRow(row, tenantId)).toList(),
    );
  }

  static DocumentLinesCompanion _lineToCompanion(
    BusinessDocument document,
    DocumentLine line,
    int index,
    String tenantId,
  ) {
    final now = DateTime.now();
    return DocumentLinesCompanion(
      id: Value(TenantRowScope.rowId(tenantId, '${document.id}-$index')),
      tenantId: Value(tenantId),
      documentId: Value(TenantRowScope.rowId(tenantId, document.id)),
      position: Value(index),
      productId: Value(TenantRowScope.nullableRowId(tenantId, line.productId)),
      label: Value(line.label),
      sku: Value(line.sku),
      quantity: Value(line.quantity),
      unitPriceHt: Value(line.unitHt),
      discount: Value(line.discountRate),
      tvaRate: Value(line.tvaRate.name),
      totalHt: Value(line.totalHt),
      totalTva: Value(line.tvaAmount),
      totalTtc: Value(line.totalTtc),
      serialNumbersJson: Value(jsonEncode(line.serialNumbers)),
      updatedAt: Value(now),
    );
  }

  static DocumentLine _lineFromRow(DocumentLineRow row, String tenantId) {
    return DocumentLine(
      productId: TenantRowScope.nullableDomainId(tenantId, row.productId) ?? '',
      label: row.label,
      sku: row.sku ?? '',
      quantity: row.quantity,
      unitHt: row.unitPriceHt,
      tvaRate: enumFromName(TvaRate.values, row.tvaRate, TvaRate.rate19),
      discountRate: row.discount,
      serialNumbers: List<String>.from(
        jsonDecode(row.serialNumbersJson) as List? ?? const [],
      ),
    );
  }

  static PaymentEntry _paymentFromRow(PaymentRow row, String tenantId) {
    return PaymentEntry(
      id: TenantRowScope.domainId(tenantId, row.id),
      date: row.date,
      amount: row.amount,
      method: enumFromName(
        PaymentMethod.values,
        row.method,
        PaymentMethod.cash,
      ),
      reference: row.reference ?? '',
      note: row.note ?? '',
    );
  }

  static CompanyProfile? _companySnapshotFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return CompanyProfile.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  static int _sequenceFromNumber(String number) {
    final match = RegExp(r'(\d+)$').firstMatch(number);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }
}
