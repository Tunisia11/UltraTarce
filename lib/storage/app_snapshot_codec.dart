import 'dart:convert';
import 'dart:typed_data';

import '../app/app_assets.dart';
import '../domain/app_models.dart';

class AppSnapshotCodec {
  const AppSnapshotCodec._();

  static const int schemaVersion = 1;
  static const int backupFormatVersion = 2;
  static const int maxLogoBytes = 1600 * 1024;
  static const int maxBackupImportBytes = 5 * 1024 * 1024;
  static const int maxWarehousesImport = 100;
  static const int maxCategoriesImport = 500;
  static const int maxProductsImport = 5000;
  static const int maxPartnersImport = 10000;
  static const int maxDocumentsImport = 10000;
  static const int maxMovementsImport = 50000;
  static const int maxAuditEventsImport = 5000;
  static const int maxImportedTextLength = 1200;
  static const int maxImportedLongTextLength = 8000;

  static String encodePortableBackup(
    AppSnapshot snapshot, {
    DateTime? exportedAt,
  }) {
    final safePayload = safeSnapshot(snapshot).toJson();
    final canonicalPayload = jsonEncode(safePayload);
    final envelope = {
      'traceUltraBackup': true,
      'formatVersion': backupFormatVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'checksum': checksum(canonicalPayload),
      'payload': safePayload,
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  static AppSnapshot decodeTrustedSnapshot(String raw) {
    if (utf8.encode(raw).length > maxBackupImportBytes) {
      throw const FormatException('Sauvegarde trop volumineuse');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Sauvegarde invalide');
    }

    final map = Map<String, dynamic>.from(decoded);
    final payload = _payloadFrom(map);
    final snapshot = AppSnapshot.fromJson(payload);
    validateSnapshotShape(snapshot);
    return safeSnapshot(snapshot);
  }

  static Map<String, dynamic> _payloadFrom(Map<String, dynamic> map) {
    final rawPayload = map['payload'];
    if (map['traceUltraBackup'] == true || rawPayload is Map) {
      if (rawPayload is! Map) {
        throw const FormatException('Payload sauvegarde manquant');
      }
      final payload = Map<String, dynamic>.from(rawPayload);
      final expectedChecksum = map['checksum'] as String?;
      if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
        final actualChecksum = checksum(jsonEncode(payload));
        if (actualChecksum != expectedChecksum) {
          throw const FormatException('Sauvegarde corrompue');
        }
      }
      return payload;
    }
    return map;
  }

  static AppSnapshot safeSnapshot(AppSnapshot snapshot) {
    final safeCompany = safeCompanyProfile(snapshot.company);
    final products = [
      for (final product in snapshot.products)
        product.copyWith(imageUrl: safeRemoteImageUrl(product.imageUrl)),
    ];
    return AppSnapshot(
      company: safeCompany,
      warehouses: snapshot.warehouses,
      categories: _safeCategories(snapshot.categories, products),
      products: products,
      partners: snapshot.partners,
      documents: _safeDocuments(snapshot.documents, safeCompany),
      movements: snapshot.movements,
      sequences: snapshot.sequences,
      auditEvents: snapshot.auditEvents.take(maxAuditEventsImport).toList(),
    );
  }

  static List<BusinessDocument> _safeDocuments(
    List<BusinessDocument> documents,
    CompanyProfile fallbackCompany,
  ) {
    return [
      for (final document in documents)
        document.copyWith(
          companySnapshot: safeCompanyProfile(
            document.companySnapshot ?? fallbackCompany,
          ),
        ),
    ];
  }

  static CompanyProfile safeCompanyProfile(CompanyProfile company) {
    final safe = company.copyWith(
      logoSource: safeLogoSource(company.logoSource),
    );
    return safe.logoSource.trim().isEmpty
        ? safe.copyWith(logoSource: AppAssets.systemLogoSource)
        : safe;
  }

  static String safeRemoteImageUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || !uri.hasAuthority) {
      return '';
    }
    return uri.toString();
  }

  static String safeLogoSource(String source) {
    final value = source.trim();
    if (value.isEmpty) return AppAssets.systemLogoSource;
    if (logoAssetPath(value) != null) return value;
    if (isSafeDataLogoSource(value)) return value;
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'https' && uri.hasAuthority) {
      return uri.toString();
    }
    return AppAssets.systemLogoSource;
  }

  static String? logoAssetPath(String source) {
    final value = source.trim();
    if (value.startsWith('asset:')) {
      final path = value.substring('asset:'.length).trim();
      return _isSafeAssetPath(path) ? path : null;
    }
    if (_isSafeAssetPath(value)) return value;
    return null;
  }

  static bool isSafeDataLogoSource(String source) {
    final value = source.trim();
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return false;
    final metadata = value.substring(0, commaIndex).toLowerCase();
    final allowedMime =
        metadata.startsWith('data:image/png;') ||
        metadata.startsWith('data:image/jpeg;') ||
        metadata.startsWith('data:image/webp;');
    if (!allowedMime || !metadata.contains(';base64')) return false;
    return dataLogoBytes(value) != null;
  }

  static Uint8List? dataLogoBytes(String source) {
    final value = source.trim();
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return null;
    try {
      final bytes = base64Decode(value.substring(commaIndex + 1));
      if (bytes.length > maxLogoBytes) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  static void validateSnapshotShape(AppSnapshot snapshot) {
    void requireCount(String label, int count, int max) {
      if (count > max) {
        throw FormatException('$label trop volumineux');
      }
    }

    void requireText(String value, String label, {bool long = false}) {
      final max = long ? maxImportedLongTextLength : maxImportedTextLength;
      if (value.length > max) {
        throw FormatException('$label trop long');
      }
    }

    requireCount('Dépôts', snapshot.warehouses.length, maxWarehousesImport);
    requireCount('Catégories', snapshot.categories.length, maxCategoriesImport);
    requireCount('Produits', snapshot.products.length, maxProductsImport);
    requireCount('Tiers', snapshot.partners.length, maxPartnersImport);
    requireCount('Documents', snapshot.documents.length, maxDocumentsImport);
    requireCount('Mouvements', snapshot.movements.length, maxMovementsImport);
    requireCount('Audit', snapshot.auditEvents.length, maxAuditEventsImport);

    final company = snapshot.company;
    requireText(company.name, 'Nom société');
    requireText(company.taxId, 'Matricule fiscal');
    requireText(company.address, 'Adresse société', long: true);
    requireText(company.phone, 'Téléphone société');
    requireText(company.email, 'Email société');
    requireText(company.logoSource, 'Logo société', long: true);
    requireText(company.invoiceFooter, 'Pied de page facture', long: true);
    requireText(company.legalInfo, 'Informations légales', long: true);

    for (final warehouse in snapshot.warehouses) {
      requireText(warehouse.id, 'ID dépôt');
      requireText(warehouse.name, 'Nom dépôt');
      requireText(warehouse.city, 'Ville dépôt');
      requireText(warehouse.code, 'Code dépôt');
      requireText(warehouse.address, 'Adresse dépôt', long: true);
    }
    for (final category in snapshot.categories) {
      requireText(category.id, 'ID catégorie');
      requireText(category.name, 'Nom catégorie');
    }
    for (final product in snapshot.products) {
      requireText(product.id, 'ID produit');
      requireText(product.name, 'Nom produit');
      requireText(product.sku, 'SKU produit');
      requireText(product.category, 'Catégorie produit');
      requireText(product.imageUrl, 'Image produit', long: true);
      requireText(product.barcode ?? '', 'Code-barres produit');
      requireText(product.brand, 'Marque produit');
      requireText(product.description, 'Description produit', long: true);
      for (final entry in product.serialsByWarehouse.entries) {
        requireText(entry.key, 'Dépôt numéro de série');
        requireCount(
          'Numéros de série produit',
          entry.value.length,
          maxMovementsImport,
        );
        for (final serial in entry.value) {
          requireText(serial, 'Numéro de série');
        }
      }
    }
    for (final partner in snapshot.partners) {
      requireText(partner.id, 'ID tiers');
      requireText(partner.name, 'Nom tiers');
      requireText(partner.taxId, 'Matricule tiers');
      requireText(partner.address, 'Adresse tiers', long: true);
      requireText(partner.phone, 'Téléphone tiers');
      requireText(partner.email, 'Email tiers');
      requireText(partner.companyName, 'Société tiers');
      requireText(partner.contactName, 'Contact tiers');
      requireText(partner.city, 'Ville tiers');
      requireText(partner.notes, 'Notes tiers', long: true);
    }
    for (final document in snapshot.documents) {
      requireText(document.id, 'ID document');
      requireText(document.number, 'Numéro document');
      requireText(document.partnerId, 'ID tiers document');
      requireText(document.partnerName, 'Tiers document');
      requireText(document.partnerTaxId, 'Matricule document');
      requireText(document.partnerAddress, 'Adresse document', long: true);
      requireText(document.warehouseId, 'Dépôt document');
      requireText(document.sourceNumber ?? '', 'Source document');
      requireText(document.note ?? '', 'Note document', long: true);
      requireCount('Lignes document', document.lines.length, 500);
      requireCount('Paiements document', document.payments.length, 500);
      for (final line in document.lines) {
        requireText(line.productId, 'ID ligne');
        requireText(line.label, 'Libellé ligne');
        requireText(line.sku, 'SKU ligne');
        requireCount('Séries ligne', line.serialNumbers.length, 1000);
        for (final serial in line.serialNumbers) {
          requireText(serial, 'Série ligne');
        }
      }
      for (final payment in document.payments) {
        requireText(payment.id, 'ID paiement');
        requireText(payment.reference, 'Référence paiement');
        requireText(payment.note, 'Note paiement', long: true);
      }
    }
    for (final movement in snapshot.movements) {
      requireText(movement.productId, 'ID mouvement');
      requireText(movement.productName, 'Produit mouvement');
      requireText(movement.documentNumber, 'Document mouvement');
      requireText(movement.warehouseId, 'Dépôt mouvement');
      requireCount('Séries mouvement', movement.serialNumbers.length, 1000);
      for (final serial in movement.serialNumbers) {
        requireText(serial, 'Série mouvement');
      }
    }
    for (final event in snapshot.auditEvents) {
      requireText(event.id, 'ID audit');
      requireText(event.actor, 'Acteur audit');
      requireText(event.action, 'Action audit');
      requireText(event.target, 'Cible audit');
      requireText(event.detail, 'Détail audit', long: true);
    }
  }

  static String checksum(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static List<Category> _safeCategories(
    List<Category> categories,
    List<Product> products,
  ) {
    if (categories.isNotEmpty) return categories;
    final names =
        products
            .map((product) => product.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (names.isEmpty) {
      return const [Category(id: 'cat-default', name: 'Général')];
    }
    return [
      for (final name in names)
        Category(id: 'cat-${checksum(name)}', name: name),
    ];
  }

  static bool _isSafeAssetPath(String value) {
    return value.startsWith('assets/') &&
        !value.contains('..') &&
        !value.contains('\\');
  }
}
