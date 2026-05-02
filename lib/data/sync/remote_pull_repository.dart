import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import '../remote/remote_tables.dart';

/// Fetches all tenant business data from Supabase for cloud-to-local import.
/// Every query is filtered by tenant_id and uses normal authenticated RLS.
class RemotePullRepository {
  RemotePullRepository(this._client);

  final SupabaseClient _client;

  /// Pull the tenant dataset from Supabase in dependency order.
  /// If [since] is provided, only pulls rows updated after that time.
  Future<RemotePullResult> pullTenantData(
    String tenantId, {
    DateTime? since,
  }) async {
    final company = await _pullCompany(tenantId, since: since);
    final warehouses = await _pullWarehouses(tenantId, since: since);
    final categories = await _pullCategories(tenantId, since: since);
    final products = await _pullProducts(tenantId, since: since);
    final partners = await _pullPartners(tenantId, since: since);
    final documents = await _pullDocuments(tenantId, since: since);
    final documentLines = await _pullDocumentLines(tenantId, since: since);
    final payments = await _pullPayments(tenantId, since: since);
    final stockMovements = await _pullStockMovements(tenantId, since: since);
    final auditEvents = await _pullAuditEvents(tenantId, since: since);
    final settings = await _pullSettings(tenantId, since: since);

    return RemotePullResult(
      company: company,
      warehouses: warehouses,
      categories: categories,
      products: products,
      partners: partners,
      documents: documents,
      documentLines: documentLines,
      payments: payments,
      stockMovements: stockMovements,
      auditEvents: auditEvents,
      settings: settings,
      pulledAt: DateTime.now(),
    );
  }

  Future<CompanyProfile?> _pullCompany(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.companies)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query.maybeSingle();
    if (res == null) return null;
    final fiscal = res['fiscal_settings'] as Map<String, dynamic>? ?? {};
    final address = (res['address'] as String? ?? '').split(' - ');
    return CompanyProfile(
      name: res['name'] as String? ?? '',
      taxId: res['tax_id'] as String? ?? '',
      address: address.isNotEmpty ? address[0] : '',
      city: address.length > 1 ? address[1] : '',
      phone: res['phone'] as String? ?? '',
      email: res['email'] as String? ?? '',
      logoSource: res['logo_path'] as String? ?? '',
      invoiceFooter:
          fiscal['invoiceFooter'] as String? ?? 'Merci pour votre confiance.',
      legalInfo: res['legal_name'] as String? ?? '',
      timbreFiscalEnabled: fiscal['timbreFiscalEnabled'] as bool? ?? true,
      timbreFiscalAmount: (fiscal['timbreFiscalAmount'] as num? ?? 1)
          .toDouble(),
    );
  }

  Future<List<RemoteWarehouse>> _pullWarehouses(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.warehouses)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemoteWarehouse.fromRow(row)).toList();
  }

  Future<List<RemoteCategory>> _pullCategories(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.categories)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemoteCategory.fromRow(row)).toList();
  }

  Future<List<RemoteProduct>> _pullProducts(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.products)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemoteProduct.fromRow(row)).toList();
  }

  Future<List<RemotePartner>> _pullPartners(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.partners)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemotePartner.fromRow(row)).toList();
  }

  Future<List<RemoteDocument>> _pullDocuments(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.documents)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query.order('created_at', ascending: true);
    return res.map((row) => RemoteDocument.fromRow(row)).toList();
  }

  Future<List<RemoteDocumentLine>> _pullDocumentLines(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.documentLines)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemoteDocumentLine.fromRow(row)).toList();
  }

  Future<List<RemotePayment>> _pullPayments(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.payments)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query;
    return res.map((row) => RemotePayment.fromRow(row)).toList();
  }

  Future<List<StockMovement>> _pullStockMovements(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.stockMovements)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query.order('created_at', ascending: true);
    return res.map((row) => _stockMovementFromRow(row)).toList();
  }

  Future<List<AuditEvent>> _pullAuditEvents(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.auditEvents)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.or(
        'updated_at.gt.${since.toUtc().toIso8601String()},deleted_at.gt.${since.toUtc().toIso8601String()}',
      );
    } else {
      query = query.isFilter('deleted_at', null);
    }
    final res = await query.order('created_at', ascending: true);
    return res
        .map(
          (row) => AuditEvent(
            id: row['id'] as String,
            date:
                DateTime.tryParse(row['created_at'] as String? ?? '') ??
                DateTime.now(),
            actor: (row['metadata'] as Map?)?['actor'] as String? ?? 'Cloud',
            action: row['type'] as String? ?? '',
            target: row['entity_type'] as String? ?? '',
            detail: row['description'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<Map<String, String>> _pullSettings(
    String tenantId, {
    DateTime? since,
  }) async {
    var query = _client
        .from(RemoteTables.settings)
        .select()
        .eq('tenant_id', tenantId);
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final res = await query;
    final map = <String, String>{};
    for (final row in res) {
      final key = row['key'] as String? ?? '';
      final value = row['value_json'];
      if (key.isNotEmpty) {
        map[key] = value is Map ? jsonEncode(value) : '$value';
      }
    }
    return map;
  }

  StockMovement _stockMovementFromRow(Map<String, dynamic> row) {
    final delta = (row['quantity_delta'] as num? ?? 0).toInt();
    final direction = delta >= 0
        ? StockDirection.inbound
        : StockDirection.outbound;
    final noteJson = _tryDecodeJson(row['note'] as String?);
    return StockMovement(
      date:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      productId: row['product_id'] as String? ?? '',
      productName: noteJson?['productName'] as String? ?? '',
      documentNumber: row['reason'] as String? ?? '',
      sourceDocumentId: row['source_document_id'] as String?,
      direction: direction,
      quantity: delta.abs(),
      warehouseId: row['warehouse_id'] as String? ?? '',
      serialNumbers: List<String>.from(
        noteJson?['serialNumbers'] as List? ?? const [],
      ),
    );
  }

  static TvaRate _parseTvaRate(Object? value) {
    final num = double.tryParse('${value ?? ''}') ?? 19;
    if (num <= 0) return TvaRate.rate0;
    if (num <= 7) return TvaRate.rate7;
    if (num <= 13) return TvaRate.rate13;
    return TvaRate.rate19;
  }

  static Map<String, dynamic>? _tryDecodeJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}

/// Holds the raw result from pulling remote data.
class RemotePullResult {
  const RemotePullResult({
    this.company,
    this.warehouses = const [],
    this.categories = const [],
    this.products = const [],
    this.partners = const [],
    this.documents = const [],
    this.documentLines = const [],
    this.payments = const [],
    this.stockMovements = const [],
    this.auditEvents = const [],
    this.settings = const {},
    this.pulledAt,
  });

  final CompanyProfile? company;
  final List<RemoteWarehouse> warehouses;
  final List<RemoteCategory> categories;
  final List<RemoteProduct> products;
  final List<RemotePartner> partners;
  final List<RemoteDocument> documents;
  final List<RemoteDocumentLine> documentLines;
  final List<RemotePayment> payments;
  final List<StockMovement> stockMovements;
  final List<AuditEvent> auditEvents;
  final Map<String, String> settings;
  final DateTime? pulledAt;

  bool get isEmpty =>
      company == null &&
      warehouses.isEmpty &&
      products.isEmpty &&
      partners.isEmpty &&
      documents.isEmpty;

  int get totalRows =>
      (company != null ? 1 : 0) +
      warehouses.length +
      categories.length +
      products.length +
      partners.length +
      documents.length +
      documentLines.length +
      payments.length +
      stockMovements.length +
      auditEvents.length +
      settings.length;

  /// Assemble into a full AppSnapshot with documents reassembled.
  AppSnapshot toSnapshot() {
    final linesGrouped = <String, List<RemoteDocumentLine>>{};
    for (final l in documentLines) {
      (linesGrouped[l.documentId] ??= []).add(l);
    }
    final paymentsGrouped = <String, List<RemotePayment>>{};
    for (final p in payments) {
      (paymentsGrouped[p.documentId] ??= []).add(p);
    }

    final assembledDocs = <BusinessDocument>[];
    for (final doc in documents) {
      final lines = linesGrouped[doc.id] ?? const [];
      final pays = paymentsGrouped[doc.id] ?? const [];
      assembledDocs.add(doc.toBusinessDocument(lines, pays));
    }

    return AppSnapshot(
      company:
          company ??
          const CompanyProfile(
            name: '',
            taxId: '',
            address: '',
            city: '',
            phone: '',
            email: '',
            logoSource: '',
            invoiceFooter: 'Merci pour votre confiance.',
          ),
      warehouses: warehouses.map((w) => w.toWarehouse()).toList(),
      categories: categories.map((c) => c.toCategory()).toList(),
      products: products.map((p) => p.toProduct()).toList(),
      partners: partners.map((p) => p.toPartner()).toList(),
      documents: assembledDocs,
      movements: stockMovements,
      sequences: _inferSequences(assembledDocs),
      auditEvents: auditEvents,
    );
  }

  Map<DocumentType, int> _inferSequences(List<BusinessDocument> docs) {
    final seqs = <DocumentType, int>{};
    for (final type in DocumentType.values) {
      seqs[type] = 1;
    }
    for (final doc in docs) {
      final match = RegExp(r'(\d+)$').firstMatch(doc.number);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num >= (seqs[doc.type] ?? 0)) {
          seqs[doc.type] = num + 1;
        }
      }
    }
    return seqs;
  }
}

// ── Internal remote DTOs ──

class RemoteWarehouse {
  RemoteWarehouse({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.isActive,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String type;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemoteWarehouse.fromRow(Map<String, dynamic> row) {
    return RemoteWarehouse(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      description: row['description'] as String?,
      type: row['type'] as String? ?? 'depot',
      isActive: row['is_active'] as bool? ?? true,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  Warehouse toWarehouse() {
    return Warehouse(
      id: id,
      name: name,
      city: '',
      code: '',
      address: description ?? '',
      type: type,
      active: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'is_active': isActive,
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class RemoteCategory {
  RemoteCategory({
    required this.id,
    required this.name,
    required this.isActive,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemoteCategory.fromRow(Map<String, dynamic> row) {
    return RemoteCategory(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      isActive: row['is_active'] as bool? ?? true,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  Category toCategory() {
    return Category(id: id, name: name, active: isActive);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_active': isActive,
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class RemoteProduct {
  RemoteProduct({
    required this.id,
    required this.name,
    this.sku,
    this.categoryName,
    this.purchasePriceHt = 0,
    this.salePriceHt = 0,
    required this.tvaRate,
    this.stockMinimum = 0,
    this.imagePath,
    this.barcode,
    this.brand,
    this.description,
    required this.isActive,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String? sku;
  final String? categoryName;
  final double purchasePriceHt;
  final double salePriceHt;
  final TvaRate tvaRate;
  final int stockMinimum;
  final String? imagePath;
  final String? barcode;
  final String? brand;
  final String? description;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemoteProduct.fromRow(Map<String, dynamic> row) {
    return RemoteProduct(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      sku: row['sku'] as String?,
      categoryName: row['category_name'] as String?,
      purchasePriceHt: (row['purchase_price_ht'] as num? ?? 0).toDouble(),
      salePriceHt: (row['sale_price_ht'] as num? ?? 0).toDouble(),
      tvaRate: RemotePullRepository._parseTvaRate(row['tva_rate']),
      stockMinimum: (row['stock_minimum'] as num? ?? 0).toInt(),
      imagePath: row['image_path'] as String?,
      barcode: row['barcode'] as String?,
      brand: row['brand'] as String?,
      description: row['description'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  Product toProduct() {
    return Product(
      id: id,
      name: name,
      sku: sku ?? '',
      category: categoryName ?? '',
      purchaseHt: purchasePriceHt,
      saleHt: salePriceHt,
      tvaRate: tvaRate,
      minStock: stockMinimum,
      serialTracked: false,
      stockByWarehouse: const {},
      serialsByWarehouse: const {},
      imageUrl: imagePath ?? '',
      barcode: barcode,
      brand: brand ?? '',
      description: description ?? '',
      active: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category_name': categoryName,
    'purchase_price_ht': purchasePriceHt,
    'sale_price_ht': salePriceHt,
    'tva_rate': tvaRate.value,
    'stock_minimum': stockMinimum,
    'image_path': imagePath,
    'barcode': barcode,
    'brand': brand,
    'description': description,
    'is_active': isActive,
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class RemotePartner {
  RemotePartner({
    required this.id,
    required this.type,
    required this.name,
    this.taxId,
    this.address,
    this.phone,
    this.email,
    this.notes,
    required this.isActive,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final PartnerType type;
  final String name;
  final String? taxId;
  final String? address;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isActive;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemotePartner.fromRow(Map<String, dynamic> row) {
    return RemotePartner(
      id: row['id'] as String,
      type: (row['type'] as String?) == 'supplier'
          ? PartnerType.supplier
          : PartnerType.client,
      name: row['name'] as String? ?? '',
      taxId: row['tax_id'] as String?,
      address: row['address'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      notes: row['notes'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  Partner toPartner() {
    return Partner(
      id: id,
      type: type,
      name: name,
      taxId: taxId ?? '',
      address: address ?? '',
      phone: phone ?? '',
      email: email ?? '',
      notes: notes ?? '',
      active: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'tax_id': taxId,
    'address': address,
    'phone': phone,
    'email': email,
    'notes': notes,
    'is_active': isActive,
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class RemoteDocument {
  RemoteDocument({
    required this.id,
    required this.type,
    required this.status,
    required this.number,
    required this.partnerId,
    required this.issueDate,
    this.subtotalHt = 0,
    this.totalTva = 0,
    this.totalTtc = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.timbreFiscal = 0,
    this.notes,
    this.warehouseId,
    this.sourceNumber,
    this.metadata,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String type;
  final String status;
  final String number;
  final String? partnerId;
  final DateTime issueDate;
  final double subtotalHt;
  final double totalTva;
  final double totalTtc;
  final double paidAmount;
  final double remainingAmount;
  final double timbreFiscal;
  final String? notes;
  final String? warehouseId;
  final String? sourceNumber;
  final Map<String, dynamic>? metadata;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemoteDocument.fromRow(Map<String, dynamic> row) {
    return RemoteDocument(
      id: row['id'] as String,
      type: row['type'] as String? ?? 'facture',
      status: row['status'] as String? ?? 'draft',
      number: row['number'] as String? ?? '',
      partnerId: row['partner_id'] as String?,
      issueDate:
          DateTime.tryParse(row['issue_date'] as String? ?? '') ??
          DateTime.now(),
      subtotalHt: (row['subtotal_ht'] as num? ?? 0).toDouble(),
      totalTva: (row['total_tva'] as num? ?? 0).toDouble(),
      totalTtc: (row['total_ttc'] as num? ?? 0).toDouble(),
      paidAmount: (row['paid_amount'] as num? ?? 0).toDouble(),
      remainingAmount: (row['remaining_amount'] as num? ?? 0).toDouble(),
      timbreFiscal: (row['timbre_fiscal'] as num? ?? 0).toDouble(),
      notes: row['notes'] as String?,
      warehouseId: row['warehouse_id'] as String?,
      sourceNumber: row['source_number'] as String?,
      metadata: row['metadata'] as Map<String, dynamic>?,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  BusinessDocument toBusinessDocument(
    List<RemoteDocumentLine> lines,
    List<RemotePayment> payments,
  ) {
    final meta = metadata ?? {};
    final docType = enumFromName(
      DocumentType.values,
      type,
      DocumentType.facture,
    );
    final docStatus = enumFromName(
      DocumentStatus.values,
      status,
      DocumentStatus.draft,
    );
    return BusinessDocument(
      id: id,
      type: docType,
      number: number,
      status: docStatus,
      partnerId: partnerId ?? '',
      partnerName: meta['partnerName'] as String? ?? '',
      partnerTaxId: meta['partnerTaxId'] as String? ?? '',
      partnerAddress: meta['partnerAddress'] as String? ?? '',
      date: issueDate,
      lines: lines.map((l) => l.toDocumentLine()).toList(),
      warehouseId: warehouseId ?? meta['warehouseId'] as String? ?? '',
      companySnapshot: meta['companySnapshot'] is Map
          ? CompanyProfile.fromJson(
              Map<String, dynamic>.from(meta['companySnapshot'] as Map),
            )
          : null,
      sourceNumber: sourceNumber ?? meta['sourceNumber'] as String?,
      note: notes,
      metadata: meta,
      stockApplied: meta['stockApplied'] as bool? ?? false,
      applyTimbreFiscal: timbreFiscal > 0,
      timbreFiscalAmount: timbreFiscal,
      payments: payments.map((p) => p.toPaymentEntry()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'status': status,
    'number': number,
    'partner_id': partnerId,
    'issue_date': issueDate.toIso8601String(),
    'subtotal_ht': subtotalHt,
    'total_tva': totalTva,
    'total_ttc': totalTtc,
    'paid_amount': paidAmount,
    'remaining_amount': remainingAmount,
    'timbre_fiscal': timbreFiscal,
    'notes': notes,
    'warehouse_id': warehouseId,
    'source_number': sourceNumber,
    'metadata': metadata,
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class RemoteDocumentLine {
  RemoteDocumentLine({
    required this.id,
    required this.documentId,
    this.productId,
    required this.label,
    this.sku,
    required this.quantity,
    required this.unitPriceHt,
    this.discount = 0,
    required this.tvaRate,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String documentId;
  final String? productId;
  final String label;
  final String? sku;
  final double quantity;
  final double unitPriceHt;
  final double discount;
  final double tvaRate;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemoteDocumentLine.fromRow(Map<String, dynamic> row) {
    return RemoteDocumentLine(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      productId: row['product_id'] as String?,
      label: row['label'] as String? ?? '',
      sku: row['sku'] as String?,
      quantity: (row['quantity'] as num? ?? 0).toDouble(),
      unitPriceHt: (row['unit_price_ht'] as num? ?? 0).toDouble(),
      discount: (row['discount'] as num? ?? 0).toDouble(),
      tvaRate: (row['tva_rate'] as num? ?? 19).toDouble(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  DocumentLine toDocumentLine() {
    return DocumentLine(
      productId: productId ?? '',
      label: label,
      sku: sku ?? '',
      quantity: quantity.toInt(),
      unitHt: unitPriceHt,
      tvaRate: RemotePullRepository._parseTvaRate(tvaRate),
      discountRate: discount,
    );
  }
}

class RemotePayment {
  RemotePayment({
    required this.id,
    required this.documentId,
    required this.amount,
    this.method,
    required this.date,
    this.reference,
    this.note,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String documentId;
  final double amount;
  final String? method;
  final DateTime date;
  final String? reference;
  final String? note;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory RemotePayment.fromRow(Map<String, dynamic> row) {
    return RemotePayment(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      amount: (row['amount'] as num? ?? 0).toDouble(),
      method: row['method'] as String?,
      date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
      reference: row['reference'] as String?,
      note: row['note'] as String?,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
      deletedAt: DateTime.tryParse(row['deleted_at'] as String? ?? ''),
    );
  }

  PaymentEntry toPaymentEntry() {
    return PaymentEntry(
      id: id,
      date: date,
      amount: amount,
      method: enumFromName(PaymentMethod.values, method, PaymentMethod.cash),
      reference: reference ?? '',
      note: note ?? '',
    );
  }
}
