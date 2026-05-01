import 'app_enums.dart';

class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.taxId,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.logoSource,
    required this.invoiceFooter,
    this.legalInfo = '',
    this.timbreFiscalEnabled = true,
    this.timbreFiscalAmount = 1,
  });

  final String name;
  final String taxId;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String logoSource;
  final String invoiceFooter;
  final String legalInfo;
  final bool timbreFiscalEnabled;
  final double timbreFiscalAmount;

  Map<String, dynamic> toJson() => {
    'name': name,
    'taxId': taxId,
    'address': address,
    'city': city,
    'phone': phone,
    'email': email,
    'logoSource': logoSource,
    'invoiceFooter': invoiceFooter,
    'legalInfo': legalInfo,
    'timbreFiscalEnabled': timbreFiscalEnabled,
    'timbreFiscalAmount': timbreFiscalAmount,
  };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name: json['name'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoSource: json['logoSource'] as String? ?? '',
      invoiceFooter:
          json['invoiceFooter'] as String? ?? 'Merci pour votre confiance.',
      legalInfo: json['legalInfo'] as String? ?? '',
      timbreFiscalEnabled: json['timbreFiscalEnabled'] as bool? ?? true,
      timbreFiscalAmount: (json['timbreFiscalAmount'] as num? ?? 1).toDouble(),
    );
  }

  CompanyProfile copyWith({
    String? name,
    String? taxId,
    String? address,
    String? city,
    String? phone,
    String? email,
    String? logoSource,
    String? invoiceFooter,
    String? legalInfo,
    bool? timbreFiscalEnabled,
    double? timbreFiscalAmount,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoSource: logoSource ?? this.logoSource,
      invoiceFooter: invoiceFooter ?? this.invoiceFooter,
      legalInfo: legalInfo ?? this.legalInfo,
      timbreFiscalEnabled: timbreFiscalEnabled ?? this.timbreFiscalEnabled,
      timbreFiscalAmount: timbreFiscalAmount ?? this.timbreFiscalAmount,
    );
  }
}

class Warehouse {
  const Warehouse({
    required this.id,
    required this.name,
    required this.city,
    this.code = '',
    this.address = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String city;
  final String code;
  final String address;
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'code': code,
    'address': address,
    'active': active,
  };

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      code: json['code'] as String? ?? '',
      address: json['address'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Warehouse copyWith({
    String? name,
    String? city,
    String? code,
    String? address,
    bool? active,
  }) {
    return Warehouse(
      id: id,
      name: name ?? this.name,
      city: city ?? this.city,
      code: code ?? this.code,
      address: address ?? this.address,
      active: active ?? this.active,
    );
  }
}

class Category {
  const Category({required this.id, required this.name, this.active = true});

  final String id;
  final String name;
  final bool active;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'active': active};

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Category copyWith({String? name, bool? active}) {
    return Category(
      id: id,
      name: name ?? this.name,
      active: active ?? this.active,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.purchaseHt,
    required this.saleHt,
    required this.tvaRate,
    required this.minStock,
    required this.serialTracked,
    required this.stockByWarehouse,
    required this.serialsByWarehouse,
    required this.imageUrl,
    this.barcode,
    this.brand = '',
    this.description = '',
    this.stockTracked = true,
    this.active = true,
  });

  final String id;
  final String name;
  final String sku;
  final String category;
  final double purchaseHt;
  final double saleHt;
  final TvaRate tvaRate;
  final int minStock;
  final bool serialTracked;
  final Map<String, int> stockByWarehouse;
  final Map<String, List<String>> serialsByWarehouse;
  final String imageUrl;
  final String? barcode;
  final String brand;
  final String description;
  final bool stockTracked;
  final bool active;

  int get totalStock =>
      stockByWarehouse.values.fold(0, (total, quantity) => total + quantity);

  double get saleTtc => saleHt * (1 + tvaRate.multiplier);

  int stockIn(String warehouseId) => stockByWarehouse[warehouseId] ?? 0;

  List<String> serialsIn(String warehouseId) =>
      serialsByWarehouse[warehouseId] ?? const [];

  Product copyWith({
    String? name,
    String? sku,
    String? category,
    double? purchaseHt,
    double? saleHt,
    TvaRate? tvaRate,
    int? minStock,
    bool? serialTracked,
    Map<String, int>? stockByWarehouse,
    Map<String, List<String>>? serialsByWarehouse,
    String? imageUrl,
    String? barcode,
    String? brand,
    String? description,
    bool? stockTracked,
    bool? active,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      purchaseHt: purchaseHt ?? this.purchaseHt,
      saleHt: saleHt ?? this.saleHt,
      tvaRate: tvaRate ?? this.tvaRate,
      minStock: minStock ?? this.minStock,
      serialTracked: serialTracked ?? this.serialTracked,
      stockByWarehouse:
          stockByWarehouse ?? Map<String, int>.from(this.stockByWarehouse),
      serialsByWarehouse:
          serialsByWarehouse ??
          this.serialsByWarehouse.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      stockTracked: stockTracked ?? this.stockTracked,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category': category,
    'purchaseHt': purchaseHt,
    'saleHt': saleHt,
    'tvaRate': tvaRate.name,
    'minStock': minStock,
    'serialTracked': serialTracked,
    'stockByWarehouse': stockByWarehouse,
    'serialsByWarehouse': serialsByWarehouse,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'brand': brand,
    'description': description,
    'stockTracked': stockTracked,
    'active': active,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    final stockSource = json['stockByWarehouse'] as Map? ?? const {};
    final serialSource = json['serialsByWarehouse'] as Map? ?? const {};
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      category: json['category'] as String? ?? '',
      purchaseHt: (json['purchaseHt'] as num? ?? 0).toDouble(),
      saleHt: (json['saleHt'] as num? ?? 0).toDouble(),
      tvaRate: enumFromName(TvaRate.values, json['tvaRate'], TvaRate.rate19),
      minStock: (json['minStock'] as num? ?? 0).toInt(),
      serialTracked: json['serialTracked'] as bool? ?? false,
      stockByWarehouse: stockSource.map(
        (key, value) => MapEntry('$key', (value as num? ?? 0).toInt()),
      ),
      serialsByWarehouse: serialSource.map(
        (key, value) => MapEntry('$key', List<String>.from(value as List)),
      ),
      imageUrl: json['imageUrl'] as String? ?? '',
      barcode: json['barcode'] as String?,
      brand: json['brand'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stockTracked: json['stockTracked'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
    );
  }
}

class Partner {
  const Partner({
    required this.id,
    required this.type,
    required this.name,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
    this.customerType = CustomerType.entreprise,
    this.companyName = '',
    this.contactName = '',
    this.city = '',
    this.notes = '',
    this.active = true,
  });

  final String id;
  final PartnerType type;
  final String name;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final CustomerType customerType;
  final String companyName;
  final String contactName;
  final String city;
  final String notes;
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'taxId': taxId,
    'address': address,
    'phone': phone,
    'email': email,
    'customerType': customerType.name,
    'companyName': companyName,
    'contactName': contactName,
    'city': city,
    'notes': notes,
    'active': active,
  };

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String? ?? '',
      type: enumFromName(PartnerType.values, json['type'], PartnerType.client),
      name: json['name'] as String? ?? '',
      taxId: json['taxId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      customerType: enumFromName(
        CustomerType.values,
        json['customerType'],
        CustomerType.entreprise,
      ),
      companyName: json['companyName'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Partner copyWith({
    PartnerType? type,
    String? name,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    CustomerType? customerType,
    String? companyName,
    String? contactName,
    String? city,
    String? notes,
    bool? active,
  }) {
    return Partner(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customerType: customerType ?? this.customerType,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      active: active ?? this.active,
    );
  }
}

class DocumentLine {
  const DocumentLine({
    required this.productId,
    required this.label,
    required this.sku,
    required this.quantity,
    required this.unitHt,
    required this.tvaRate,
    this.discountRate = 0,
    this.serialNumbers = const [],
  });

  final String productId;
  final String label;
  final String sku;
  final int quantity;
  final double unitHt;
  final TvaRate tvaRate;
  final double discountRate;
  final List<String> serialNumbers;

  double get grossHt => unitHt * quantity;
  double get discountAmount => grossHt * (discountRate.clamp(0, 100) / 100);
  double get totalHt => grossHt - discountAmount;
  double get tvaAmount => totalHt * tvaRate.multiplier;
  double get totalTtc => totalHt + tvaAmount;

  DocumentLine copyWith({
    int? quantity,
    double? unitHt,
    TvaRate? tvaRate,
    double? discountRate,
    List<String>? serialNumbers,
  }) {
    return DocumentLine(
      productId: productId,
      label: label,
      sku: sku,
      quantity: quantity ?? this.quantity,
      unitHt: unitHt ?? this.unitHt,
      tvaRate: tvaRate ?? this.tvaRate,
      discountRate: discountRate ?? this.discountRate,
      serialNumbers: serialNumbers ?? this.serialNumbers,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'label': label,
    'sku': sku,
    'quantity': quantity,
    'unitHt': unitHt,
    'tvaRate': tvaRate.name,
    'discountRate': discountRate,
    'serialNumbers': serialNumbers,
  };

  factory DocumentLine.fromJson(Map<String, dynamic> json) {
    return DocumentLine(
      productId: json['productId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      unitHt: (json['unitHt'] as num? ?? 0).toDouble(),
      tvaRate: enumFromName(TvaRate.values, json['tvaRate'], TvaRate.rate19),
      discountRate: (json['discountRate'] as num? ?? 0).toDouble(),
      serialNumbers: List<String>.from(
        json['serialNumbers'] as List? ?? const [],
      ),
    );
  }
}

class PaymentEntry {
  const PaymentEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    this.reference = '',
    this.note = '',
  });

  final String id;
  final DateTime date;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'amount': amount,
    'method': method.name,
    'reference': reference,
    'note': note,
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      method: enumFromName(
        PaymentMethod.values,
        json['method'],
        PaymentMethod.cash,
      ),
      reference: json['reference'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class BusinessDocument {
  const BusinessDocument({
    required this.id,
    required this.type,
    required this.number,
    required this.status,
    required this.partnerId,
    required this.partnerName,
    required this.partnerTaxId,
    required this.partnerAddress,
    required this.date,
    required this.lines,
    required this.warehouseId,
    this.companySnapshot,
    this.sourceNumber,
    this.note,
    this.stockApplied = false,
    this.applyTimbreFiscal = false,
    this.timbreFiscalAmount = 0,
    this.payments = const [],
  });

  final String id;
  final DocumentType type;
  final String number;
  final DocumentStatus status;
  final String partnerId;
  final String partnerName;
  final String partnerTaxId;
  final String partnerAddress;
  final DateTime date;
  final List<DocumentLine> lines;
  final String warehouseId;
  final CompanyProfile? companySnapshot;
  final String? sourceNumber;
  final String? note;
  final bool stockApplied;
  final bool applyTimbreFiscal;
  final double timbreFiscalAmount;
  final List<PaymentEntry> payments;

  bool get isLocked =>
      status == DocumentStatus.validated || status == DocumentStatus.canceled;
  bool get isCanceled => status == DocumentStatus.canceled;
  double get totalHt => lines.fold(0, (total, line) => total + line.totalHt);
  double get totalTva => lines.fold(0, (total, line) => total + line.tvaAmount);
  double get totalTtc => totalHt + totalTva;
  double get timbreAmount => applyTimbreFiscal ? timbreFiscalAmount : 0;
  double get netToPay => totalTtc + timbreAmount;
  double get paidAmount =>
      payments.fold(0, (total, payment) => total + payment.amount);
  double get remainingAmount =>
      (netToPay - paidAmount).clamp(0, netToPay).toDouble();
  PaymentStatus get paymentStatus {
    if (paidAmount <= 0) return PaymentStatus.unpaid;
    if (paidAmount + .001 >= netToPay) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  Map<TvaRate, double> get tvaBreakdown {
    final values = <TvaRate, double>{};
    for (final line in lines) {
      values[line.tvaRate] = (values[line.tvaRate] ?? 0) + line.tvaAmount;
    }
    return values;
  }

  BusinessDocument copyWith({
    DocumentStatus? status,
    List<DocumentLine>? lines,
    CompanyProfile? companySnapshot,
    bool? stockApplied,
    bool? applyTimbreFiscal,
    double? timbreFiscalAmount,
    List<PaymentEntry>? payments,
  }) {
    return BusinessDocument(
      id: id,
      type: type,
      number: number,
      status: status ?? this.status,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerTaxId: partnerTaxId,
      partnerAddress: partnerAddress,
      date: date,
      lines: lines ?? this.lines,
      warehouseId: warehouseId,
      companySnapshot: companySnapshot ?? this.companySnapshot,
      sourceNumber: sourceNumber,
      note: note,
      stockApplied: stockApplied ?? this.stockApplied,
      applyTimbreFiscal: applyTimbreFiscal ?? this.applyTimbreFiscal,
      timbreFiscalAmount: timbreFiscalAmount ?? this.timbreFiscalAmount,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'number': number,
    'status': status.name,
    'partnerId': partnerId,
    'partnerName': partnerName,
    'partnerTaxId': partnerTaxId,
    'partnerAddress': partnerAddress,
    'date': date.toIso8601String(),
    'lines': lines.map((line) => line.toJson()).toList(),
    'warehouseId': warehouseId,
    'companySnapshot': companySnapshot?.toJson(),
    'sourceNumber': sourceNumber,
    'note': note,
    'stockApplied': stockApplied,
    'applyTimbreFiscal': applyTimbreFiscal,
    'timbreFiscalAmount': timbreFiscalAmount,
    'payments': payments.map((payment) => payment.toJson()).toList(),
  };

  factory BusinessDocument.fromJson(Map<String, dynamic> json) {
    return BusinessDocument(
      id: json['id'] as String? ?? '',
      type: enumFromName(DocumentType.values, json['type'], DocumentType.devis),
      number: json['number'] as String? ?? '',
      status: enumFromName(
        DocumentStatus.values,
        json['status'],
        DocumentStatus.draft,
      ),
      partnerId: json['partnerId'] as String? ?? '',
      partnerName: json['partnerName'] as String? ?? '',
      partnerTaxId: json['partnerTaxId'] as String? ?? '',
      partnerAddress: json['partnerAddress'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2026),
      lines: (json['lines'] as List? ?? const [])
          .map(
            (line) =>
                DocumentLine.fromJson(Map<String, dynamic>.from(line as Map)),
          )
          .toList(),
      warehouseId: json['warehouseId'] as String? ?? '',
      companySnapshot: json['companySnapshot'] is Map
          ? CompanyProfile.fromJson(
              Map<String, dynamic>.from(json['companySnapshot'] as Map),
            )
          : null,
      sourceNumber: json['sourceNumber'] as String?,
      note: json['note'] as String?,
      stockApplied: json['stockApplied'] as bool? ?? false,
      applyTimbreFiscal: json['applyTimbreFiscal'] as bool? ?? false,
      timbreFiscalAmount: (json['timbreFiscalAmount'] as num? ?? 0).toDouble(),
      payments: (json['payments'] as List? ?? const [])
          .map(
            (payment) => PaymentEntry.fromJson(
              Map<String, dynamic>.from(payment as Map),
            ),
          )
          .toList(),
    );
  }
}

class StockMovement {
  const StockMovement({
    required this.date,
    required this.productId,
    required this.productName,
    required this.documentNumber,
    this.sourceDocumentId,
    required this.direction,
    required this.quantity,
    required this.warehouseId,
    this.serialNumbers = const [],
  });

  final DateTime date;
  final String productId;
  final String productName;
  final String documentNumber;
  final String? sourceDocumentId;
  final StockDirection direction;
  final int quantity;
  final String warehouseId;
  final List<String> serialNumbers;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'productId': productId,
    'productName': productName,
    'documentNumber': documentNumber,
    'sourceDocumentId': sourceDocumentId,
    'direction': direction.name,
    'quantity': quantity,
    'warehouseId': warehouseId,
    'serialNumbers': serialNumbers,
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2026),
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      documentNumber: json['documentNumber'] as String? ?? '',
      sourceDocumentId: json['sourceDocumentId'] as String?,
      direction: enumFromName(
        StockDirection.values,
        json['direction'],
        StockDirection.outbound,
      ),
      quantity: (json['quantity'] as num? ?? 0).toInt(),
      warehouseId: json['warehouseId'] as String? ?? '',
      serialNumbers: List<String>.from(
        json['serialNumbers'] as List? ?? const [],
      ),
    );
  }
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.date,
    required this.actor,
    required this.action,
    required this.target,
    required this.detail,
  });

  final String id;
  final DateTime date;
  final String actor;
  final String action;
  final String target;
  final String detail;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'actor': actor,
    'action': action,
    'target': target,
    'detail': detail,
  };

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime(2026),
      actor: json['actor'] as String? ?? 'Système',
      action: json['action'] as String? ?? '',
      target: json['target'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.company,
    required this.warehouses,
    required this.categories,
    required this.products,
    required this.partners,
    required this.documents,
    required this.movements,
    required this.sequences,
    required this.auditEvents,
  });

  final CompanyProfile company;
  final List<Warehouse> warehouses;
  final List<Category> categories;
  final List<Product> products;
  final List<Partner> partners;
  final List<BusinessDocument> documents;
  final List<StockMovement> movements;
  final Map<DocumentType, int> sequences;
  final List<AuditEvent> auditEvents;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'company': company.toJson(),
    'warehouses': warehouses.map((warehouse) => warehouse.toJson()).toList(),
    'categories': categories.map((category) => category.toJson()).toList(),
    'products': products.map((product) => product.toJson()).toList(),
    'partners': partners.map((partner) => partner.toJson()).toList(),
    'documents': documents.map((document) => document.toJson()).toList(),
    'movements': movements.map((movement) => movement.toJson()).toList(),
    'sequences': sequences.map(
      (type, sequence) => MapEntry(type.name, sequence),
    ),
    'auditEvents': auditEvents.map((event) => event.toJson()).toList(),
  };

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    final sequenceSource = json['sequences'] as Map? ?? const {};
    return AppSnapshot(
      company: CompanyProfile.fromJson(
        Map<String, dynamic>.from(json['company'] as Map? ?? const {}),
      ),
      warehouses: (json['warehouses'] as List? ?? const [])
          .map(
            (warehouse) =>
                Warehouse.fromJson(Map<String, dynamic>.from(warehouse as Map)),
          )
          .toList(),
      categories: (json['categories'] as List? ?? const [])
          .map(
            (category) =>
                Category.fromJson(Map<String, dynamic>.from(category as Map)),
          )
          .toList(),
      products: (json['products'] as List? ?? const [])
          .map(
            (product) =>
                Product.fromJson(Map<String, dynamic>.from(product as Map)),
          )
          .toList(),
      partners: (json['partners'] as List? ?? const [])
          .map(
            (partner) =>
                Partner.fromJson(Map<String, dynamic>.from(partner as Map)),
          )
          .toList(),
      documents: (json['documents'] as List? ?? const [])
          .map(
            (document) => BusinessDocument.fromJson(
              Map<String, dynamic>.from(document as Map),
            ),
          )
          .toList(),
      movements: (json['movements'] as List? ?? const [])
          .map(
            (movement) => StockMovement.fromJson(
              Map<String, dynamic>.from(movement as Map),
            ),
          )
          .toList(),
      sequences: sequenceSource.map(
        (key, value) => MapEntry(
          enumFromName(DocumentType.values, key, DocumentType.devis),
          (value as num? ?? 1).toInt(),
        ),
      ),
      auditEvents: (json['auditEvents'] as List? ?? const [])
          .map(
            (event) =>
                AuditEvent.fromJson(Map<String, dynamic>.from(event as Map)),
          )
          .toList(),
    );
  }
}
