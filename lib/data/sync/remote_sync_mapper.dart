import 'dart:convert';

import '../../core/result/app_result.dart';
import '../remote/remote_errors.dart';
import '../remote/remote_tables.dart';
import 'sync_outbox_repository.dart';

class RemoteSyncDependency {
  const RemoteSyncDependency({required this.table, required this.id});

  final String table;
  final String id;
}

class RemoteSyncWrite {
  const RemoteSyncWrite({
    required this.table,
    required this.tenantId,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.dependencies = const [],
    this.deletedAt,
  });

  final String table;
  final String tenantId;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final List<RemoteSyncDependency> dependencies;
  final DateTime? deletedAt;

  bool get isDelete => operation == 'delete';
}

class RemoteSyncMapper {
  const RemoteSyncMapper();

  AppResult<RemoteSyncWrite> map(SyncOutboxMutation mutation) {
    final decoded = _decodePayload(mutation);
    final error = decoded.errorOrNull;
    if (error != null) return AppFailure(error);

    final envelope = decoded.valueOrNull!;
    final table = _tableFor(mutation.entityType);
    if (table == null) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.validationError,
          message: 'Type de synchronisation inconnu: ${mutation.entityType}.',
        ),
      );
    }

    final tenantId = _stringValue(envelope['tenantId']) ?? mutation.tenantId;
    if (tenantId.trim().isEmpty) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.missingTenantId,
          message: 'Aucune société sélectionnée pour la synchronisation.',
        ),
      );
    }

    final payload = Map<String, dynamic>.from(
      envelope['payload'] as Map? ?? const {},
    );
    final entityId =
        _stringValue(payload['id']) ??
        _stringValue(envelope['entityId']) ??
        mutation.entityId;
    final remoteId = remoteIdFor(tenantId, mutation.entityType, entityId);
    final common = _commonFields(
      mutation: mutation,
      tenantId: tenantId,
      remoteId: remoteId,
      envelope: envelope,
    );
    final operation = _normalOperation(mutation.operation);

    final mappedPayload = switch (mutation.entityType) {
      'companies' => _companyPayload(payload, common),
      'warehouses' => _warehousePayload(payload, common),
      'categories' => _categoryPayload(payload, common),
      'products' => _productPayload(payload, common),
      'partners' => _partnerPayload(payload, common),
      'documents' => _documentPayload(payload, common, tenantId),
      'document_lines' => _documentLinePayload(payload, common, tenantId),
      'payments' => _paymentPayload(payload, common, tenantId),
      'stock_movements' => _stockMovementPayload(payload, common, tenantId),
      'audit_events' => _auditPayload(payload, common, tenantId),
      'settings' => _settingPayload(payload, common),
      _ => null,
    };

    if (mappedPayload == null) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.validationError,
          message: 'Données distantes invalides pour ${mutation.entityType}.',
        ),
      );
    }

    return AppSuccess(
      RemoteSyncWrite(
        table: table,
        tenantId: tenantId,
        entityId: remoteId,
        operation: operation,
        payload: mappedPayload,
        deletedAt: operation == 'delete' ? mutation.updatedAt : null,
        dependencies: _dependenciesFor(
          mutation.entityType,
          mappedPayload,
          tenantId,
        ),
      ),
    );
  }

  static String remoteIdFor(String tenantId, String entityType, String id) {
    final trimmed = id.trim();
    if (_isUuid(trimmed)) return trimmed.toLowerCase();
    return _deterministicUuid('$tenantId|$entityType|$trimmed');
  }

  static String? nullableRemoteIdFor(
    String tenantId,
    String entityType,
    Object? id,
  ) {
    final value = _stringValue(id);
    if (value == null || value.isEmpty) return null;
    return remoteIdFor(tenantId, entityType, value);
  }

  AppResult<Map<String, dynamic>> _decodePayload(SyncOutboxMutation mutation) {
    try {
      final decoded = jsonDecode(mutation.payloadJson);
      if (decoded is Map) return AppSuccess(Map<String, dynamic>.from(decoded));
    } catch (error) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.validationError,
          message: 'Payload de synchronisation illisible.',
          cause: error,
        ),
      );
    }
    return const AppFailure(
      AppError(
        code: RemoteErrorCodes.validationError,
        message: 'Payload de synchronisation invalide.',
      ),
    );
  }

  String? _tableFor(String entityType) {
    return switch (entityType) {
      'companies' => RemoteTables.companies,
      'warehouses' => RemoteTables.warehouses,
      'categories' => RemoteTables.categories,
      'products' => RemoteTables.products,
      'partners' => RemoteTables.partners,
      'documents' => RemoteTables.documents,
      'document_lines' => RemoteTables.documentLines,
      'payments' => RemoteTables.payments,
      'stock_movements' => RemoteTables.stockMovements,
      'audit_events' => RemoteTables.auditEvents,
      'settings' => RemoteTables.settings,
      _ => null,
    };
  }

  Map<String, dynamic> _commonFields({
    required SyncOutboxMutation mutation,
    required String tenantId,
    required String remoteId,
    required Map<String, dynamic> envelope,
  }) {
    final userId = _stringValue(mutation.userId);
    return {
      'id': remoteId,
      'tenant_id': tenantId,
      'sync_origin_device_id':
          _stringValue(envelope['deviceId']) ?? mutation.deviceId,
      'local_updated_at': mutation.updatedAt.toUtc().toIso8601String(),
      if (userId != null && _isUuid(userId)) ...{
        'created_by': userId,
        'updated_by': userId,
      },
    };
  }

  String _normalOperation(String operation) {
    return switch (operation) {
      'insert' || 'update' || 'upsert' => 'upsert',
      'delete' => 'delete',
      _ => 'upsert',
    };
  }

  Map<String, dynamic> _companyPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    return {
      ...common,
      'name': _stringValue(payload['name']) ?? 'Société',
      'legal_name': _stringValue(payload['legalInfo']),
      'tax_id': _stringValue(payload['taxId']),
      'address': _joinNonEmpty([
        _stringValue(payload['address']),
        _stringValue(payload['city']),
      ]),
      'phone': _stringValue(payload['phone']),
      'email': _stringValue(payload['email']),
      'logo_path': _stringValue(payload['logoSource']),
      'fiscal_settings': {
        'invoiceFooter': payload['invoiceFooter'],
        'timbreFiscalEnabled': payload['timbreFiscalEnabled'],
        'timbreFiscalAmount': payload['timbreFiscalAmount'],
      },
    };
  }

  Map<String, dynamic> _warehousePayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    return {
      ...common,
      'name': _stringValue(payload['name']) ?? 'Dépôt',
      'description': _joinNonEmpty([
        _stringValue(payload['code']),
        _stringValue(payload['address']),
        _stringValue(payload['city']),
      ]),
      'is_default': payload['isDefault'] == true,
      'is_active': _boolValue(payload['active'], fallback: true),
      'deleted_at': _boolValue(payload['active'], fallback: true)
          ? null
          : DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _categoryPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    return {
      ...common,
      'name': _stringValue(payload['name']) ?? 'Catégorie',
      'is_active': _boolValue(payload['active'], fallback: true),
      'deleted_at': _boolValue(payload['active'], fallback: true)
          ? null
          : DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _productPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    return {
      ...common,
      'name': _stringValue(payload['name']) ?? 'Produit',
      'sku': _stringValue(payload['sku']),
      'barcode': _stringValue(payload['barcode']),
      'description': _stringValue(payload['description']),
      'category_id': null,
      'category_name': _stringValue(payload['category']),
      'brand': _stringValue(payload['brand']),
      'unit': 'pièce',
      'purchase_price_ht': _numValue(payload['purchaseHt']),
      'sale_price_ht': _numValue(payload['saleHt']),
      'tva_rate': _tvaRateValue(payload['tvaRate']),
      'stock_minimum': _numValue(payload['minStock']),
      'image_path': _stringValue(payload['imageUrl']),
      'is_active': _boolValue(payload['active'], fallback: true),
      'deleted_at': _boolValue(payload['active'], fallback: true)
          ? null
          : DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _partnerPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    return {
      ...common,
      'type': _stringValue(payload['type']) == 'supplier'
          ? 'supplier'
          : 'client',
      'name': _stringValue(payload['name']) ?? 'Partenaire',
      'phone': _stringValue(payload['phone']),
      'email': _stringValue(payload['email']),
      'tax_id': _stringValue(payload['taxId']),
      'address': _joinNonEmpty([
        _stringValue(payload['address']),
        _stringValue(payload['city']),
      ]),
      'notes': _joinNonEmpty([
        _stringValue(payload['notes']),
        _stringValue(payload['companyName']),
        _stringValue(payload['contactName']),
      ]),
      'is_active': _boolValue(payload['active'], fallback: true),
      'deleted_at': _boolValue(payload['active'], fallback: true)
          ? null
          : DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _documentPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
    String tenantId,
  ) {
    final totals = _documentTotals(payload);
    return {
      ...common,
      'type': _stringValue(payload['type']) ?? 'facture',
      'status': _stringValue(payload['status']) ?? 'draft',
      'number': _stringValue(payload['number']) ?? '',
      'sequence': _sequenceFromNumber(_stringValue(payload['number']) ?? ''),
      'partner_id': nullableRemoteIdFor(
        tenantId,
        'partners',
        payload['partnerId'],
      ),
      'issue_date':
          _dateString(payload['date']) ?? DateTime.now().toIso8601String(),
      'due_date': null,
      'subtotal_ht': totals.subtotalHt,
      'total_discount': totals.totalDiscount,
      'total_tva': totals.totalTva,
      'timbre_fiscal': totals.timbreFiscal,
      'total_ttc': totals.totalTtc,
      'paid_amount': totals.paidAmount,
      'remaining_amount': totals.remainingAmount,
      'notes': _stringValue(payload['note']),
      'source_document_id': null,
      'metadata': {
        'partnerName': payload['partnerName'],
        'partnerTaxId': payload['partnerTaxId'],
        'partnerAddress': payload['partnerAddress'],
        'warehouseId': payload['warehouseId'],
        'sourceNumber': payload['sourceNumber'],
        'stockApplied': payload['stockApplied'],
        'applyTimbreFiscal': payload['applyTimbreFiscal'],
        'companySnapshot': payload['companySnapshot'],
      },
    };
  }

  Map<String, dynamic> _documentLinePayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
    String tenantId,
  ) {
    final quantity = _numValue(payload['quantity']);
    final unitPrice = _numValue(payload['unitHt']);
    final discount = _numValue(payload['discountRate']);
    final grossHt = quantity * unitPrice;
    final totalHt = grossHt - (grossHt * (discount.clamp(0, 100) / 100));
    final tvaRate = _tvaRateValue(payload['tvaRate']);
    final totalTva = totalHt * (tvaRate / 100);
    return {
      ...common,
      'document_id': remoteIdFor(
        tenantId,
        'documents',
        _stringValue(payload['documentId']) ?? '',
      ),
      'product_id': nullableRemoteIdFor(
        tenantId,
        'products',
        payload['productId'],
      ),
      'label': _stringValue(payload['label']) ?? 'Article',
      'sku': _stringValue(payload['sku']),
      'quantity': quantity,
      'unit_price_ht': unitPrice,
      'discount': discount,
      'tva_rate': tvaRate,
      'total_ht': totalHt,
      'total_tva': totalTva,
      'total_ttc': totalHt + totalTva,
    };
  }

  Map<String, dynamic> _paymentPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
    String tenantId,
  ) {
    return {
      ...common,
      'document_id': remoteIdFor(
        tenantId,
        'documents',
        _stringValue(payload['documentId']) ?? '',
      ),
      'amount': _numValue(payload['amount']),
      'method': _stringValue(payload['method']),
      'date': _dateString(payload['date']) ?? DateTime.now().toIso8601String(),
      'reference': _stringValue(payload['reference']),
      'note': _stringValue(payload['note']),
    };
  }

  Map<String, dynamic> _stockMovementPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
    String tenantId,
  ) {
    final direction = _stringValue(payload['direction']);
    final quantity = _numValue(payload['quantity']);
    final quantityDelta = direction == 'inbound' ? quantity : -quantity;
    return {
      ...common,
      'product_id': remoteIdFor(
        tenantId,
        'products',
        _stringValue(payload['productId']) ?? '',
      ),
      'warehouse_id': remoteIdFor(
        tenantId,
        'warehouses',
        _stringValue(payload['warehouseId']) ?? '',
      ),
      'quantity_delta': quantityDelta,
      'type': direction ?? 'outbound',
      'reason': _stringValue(payload['documentNumber']),
      'source_document_id': nullableRemoteIdFor(
        tenantId,
        'documents',
        payload['sourceDocumentId'],
      ),
      'note': jsonEncode({
        'productName': payload['productName'],
        'serialNumbers': payload['serialNumbers'],
      }),
      'created_at':
          _dateString(payload['date']) ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _auditPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
    String tenantId,
  ) {
    return {
      ...common,
      'type': _stringValue(payload['action']) ?? 'audit',
      'title': _stringValue(payload['action']) ?? 'Audit',
      'description': _stringValue(payload['detail']),
      'entity_type': _stringValue(payload['target']),
      'entity_id': null,
      'metadata': {'actor': payload['actor'], 'target': payload['target']},
      'created_at':
          _dateString(payload['date']) ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _settingPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> common,
  ) {
    final key = _stringValue(payload['key']) ?? common['id'] as String;
    return {
      ...common,
      'key': key,
      'value_json': payload['value'] is Map
          ? Map<String, dynamic>.from(payload['value'] as Map)
          : {'value': payload['value'] ?? payload},
    };
  }

  List<RemoteSyncDependency> _dependenciesFor(
    String entityType,
    Map<String, dynamic> payload,
    String tenantId,
  ) {
    return switch (entityType) {
      'document_lines' => [
        RemoteSyncDependency(
          table: RemoteTables.documents,
          id: payload['document_id'] as String,
        ),
      ],
      'payments' => [
        RemoteSyncDependency(
          table: RemoteTables.documents,
          id: payload['document_id'] as String,
        ),
      ],
      'stock_movements' => [
        RemoteSyncDependency(
          table: RemoteTables.products,
          id: payload['product_id'] as String,
        ),
        RemoteSyncDependency(
          table: RemoteTables.warehouses,
          id: payload['warehouse_id'] as String,
        ),
        if (payload['source_document_id'] != null)
          RemoteSyncDependency(
            table: RemoteTables.documents,
            id: payload['source_document_id'] as String,
          ),
      ],
      _ => const [],
    };
  }

  _DocumentTotals _documentTotals(Map<String, dynamic> payload) {
    final lines = payload['lines'] as List? ?? const [];
    var subtotal = 0.0;
    var totalDiscount = 0.0;
    var totalTva = 0.0;
    for (final rawLine in lines) {
      if (rawLine is! Map) continue;
      final line = Map<String, dynamic>.from(rawLine);
      final quantity = _numValue(line['quantity']);
      final unit = _numValue(line['unitHt']);
      final discountRate = _numValue(line['discountRate']);
      final gross = quantity * unit;
      final discount = gross * (discountRate.clamp(0, 100) / 100);
      final ht = gross - discount;
      final tva = ht * (_tvaRateValue(line['tvaRate']) / 100);
      subtotal += ht;
      totalDiscount += discount;
      totalTva += tva;
    }
    final totalTtc = subtotal + totalTva;
    final timbre = payload['applyTimbreFiscal'] == true
        ? _numValue(payload['timbreFiscalAmount'])
        : 0.0;
    final payments = payload['payments'] as List? ?? const [];
    final paid = payments.fold<double>(0, (total, rawPayment) {
      if (rawPayment is! Map) return total;
      return total + _numValue(rawPayment['amount']);
    });
    final netToPay = totalTtc + timbre;
    return _DocumentTotals(
      subtotalHt: subtotal,
      totalDiscount: totalDiscount,
      totalTva: totalTva,
      timbreFiscal: timbre,
      totalTtc: totalTtc,
      paidAmount: paid,
      remainingAmount: (netToPay - paid).clamp(0, netToPay).toDouble(),
    );
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static bool _boolValue(Object? value, {required bool fallback}) {
    return value is bool ? value : fallback;
  }

  static double _numValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

  static double _tvaRateValue(Object? value) {
    final text = _stringValue(value) ?? '19';
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(text);
    return double.tryParse(match?.group(0) ?? '') ?? 19;
  }

  static String? _dateString(Object? value) {
    final text = _stringValue(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return (parsed ?? DateTime.tryParse('$value'))?.toUtc().toIso8601String();
  }

  static String? _joinNonEmpty(List<String?> parts) {
    final joined = parts
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' - ');
    return joined.isEmpty ? null : joined;
  }

  static int? _sequenceFromNumber(String number) {
    final match = RegExp(r'(\d+)$').firstMatch(number);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  static String _deterministicUuid(String seed) {
    final parts = [
      _fnv32('$seed|0'),
      _fnv32('$seed|1'),
      _fnv32('$seed|2'),
      _fnv32('$seed|3'),
    ];
    final first = _hex32(parts[0]);
    final second = _hex16(parts[1] >> 16);
    final third = _hex16((parts[1] & 0x0fff) | 0x5000);
    final fourth = _hex16(((parts[2] >> 16) & 0x3fff) | 0x8000);
    final fifth = '${_hex16(parts[2] & 0xffff)}${_hex32(parts[3])}';
    return '$first-$second-$third-$fourth-$fifth';
  }

  static int _fnv32(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static String _hex32(int value) {
    return (value & 0xffffffff).toRadixString(16).padLeft(8, '0');
  }

  static String _hex16(int value) {
    return (value & 0xffff).toRadixString(16).padLeft(4, '0');
  }
}

class _DocumentTotals {
  const _DocumentTotals({
    required this.subtotalHt,
    required this.totalDiscount,
    required this.totalTva,
    required this.timbreFiscal,
    required this.totalTtc,
    required this.paidAmount,
    required this.remainingAmount,
  });

  final double subtotalHt;
  final double totalDiscount;
  final double totalTva;
  final double timbreFiscal;
  final double totalTtc;
  final double paidAmount;
  final double remainingAmount;
}
