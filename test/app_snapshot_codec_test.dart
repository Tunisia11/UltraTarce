import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/app_assets.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/storage/app_snapshot_codec.dart';

void main() {
  test('encodes portable backup envelope and restores sanitized snapshot', () {
    final snapshot = _snapshot(
      categories: const [],
      companyLogoSource: 'file:///tmp/logo.png',
      productImageUrl: 'http://unsafe.example/image.png',
    );

    final encoded = AppSnapshotCodec.encodePortableBackup(
      snapshot,
      exportedAt: DateTime.utc(2026, 4, 22),
    );
    final decoded = jsonDecode(encoded) as Map;

    expect(decoded['traceUltraBackup'], isTrue);
    expect(decoded['formatVersion'], AppSnapshotCodec.backupFormatVersion);
    expect(decoded['checksum'], isA<String>());

    final restored = AppSnapshotCodec.decodeTrustedSnapshot(encoded);
    expect(restored.company.logoSource, AppAssets.systemLogoSource);
    expect(restored.products.single.imageUrl, isEmpty);
    expect(restored.categories.single.name, 'Électronique');
  });

  test('rejects backup envelope when checksum does not match payload', () {
    final encoded = AppSnapshotCodec.encodePortableBackup(_snapshot());
    final decoded = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    final payload = Map<String, dynamic>.from(decoded['payload'] as Map);
    payload['company'] = {
      ...Map<String, dynamic>.from(payload['company'] as Map),
      'name': 'Tampered Store',
    };
    decoded['payload'] = payload;

    expect(
      () => AppSnapshotCodec.decodeTrustedSnapshot(jsonEncode(decoded)),
      throwsFormatException,
    );
  });

  test('still imports legacy raw snapshot JSON', () {
    final snapshot = _snapshot();
    final restored = AppSnapshotCodec.decodeTrustedSnapshot(
      jsonEncode(snapshot.toJson()),
    );

    expect(restored.company.name, snapshot.company.name);
    expect(restored.warehouses.single.id, 'main');
  });

  test(
    'backfills document company snapshot without overwriting existing one',
    () {
      const originalCompany = CompanyProfile(
        name: 'Original Store',
        taxId: '1111111/A/M/000',
        address: 'Ancienne adresse',
        city: 'Sfax',
        phone: '+216 74 000 000',
        email: 'old@example.tn',
        logoSource: '',
        invoiceFooter: 'Ancienne mention.',
      );
      final restored = AppSnapshotCodec.decodeTrustedSnapshot(
        jsonEncode(
          _snapshot(
            documents: [
              _document(id: 'legacy', number: 'FAC-2026-0001'),
              _document(
                id: 'frozen',
                number: 'FAC-2026-0002',
                companySnapshot: originalCompany,
              ),
            ],
          ).toJson(),
        ),
      );

      expect(
        restored.documents[0].companySnapshot?.name,
        restored.company.name,
      );
      expect(restored.documents[1].companySnapshot?.name, 'Original Store');
    },
  );
}

AppSnapshot _snapshot({
  List<Category> categories = const [
    Category(id: 'cat-default', name: 'Électronique'),
  ],
  String companyLogoSource = '',
  String productImageUrl = '',
  List<BusinessDocument> documents = const [],
}) {
  return AppSnapshot(
    company: CompanyProfile(
      name: 'Trace Ultra Store',
      taxId: '1234567/A/M/000',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      phone: '+216 20 000 000',
      email: 'contact@trace.tn',
      logoSource: companyLogoSource,
      invoiceFooter: 'Merci.',
    ),
    warehouses: const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: categories,
    products: [
      Product(
        id: 'p1',
        name: 'TV Samsung',
        sku: 'TV-SAM',
        category: 'Électronique',
        purchaseHt: 800,
        saleHt: 1000,
        tvaRate: TvaRate.rate19,
        minStock: 2,
        serialTracked: false,
        stockByWarehouse: const {'main': 3},
        serialsByWarehouse: const {'main': []},
        imageUrl: productImageUrl,
      ),
    ],
    partners: const [],
    documents: documents,
    movements: const [],
    sequences: const {DocumentType.facture: 1},
    auditEvents: const [],
  );
}

BusinessDocument _document({
  required String id,
  required String number,
  CompanyProfile? companySnapshot,
}) {
  return BusinessDocument(
    id: id,
    type: DocumentType.facture,
    number: number,
    status: DocumentStatus.validated,
    partnerId: 'c1',
    partnerName: 'Client Test',
    partnerTaxId: '0987654/B/M/000',
    partnerAddress: 'Tunis',
    date: DateTime(2026, 4, 22),
    lines: const [
      DocumentLine(
        productId: 'p1',
        label: 'TV Samsung',
        sku: 'TV-SAM',
        quantity: 1,
        unitHt: 1000,
        tvaRate: TvaRate.rate19,
      ),
    ],
    warehouseId: 'main',
    companySnapshot: companySnapshot,
  );
}
