import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/main.dart';

void main() {
  test('calculates HT, TVA, and TTC totals', () {
    const line = DocumentLine(
      productId: 'p1',
      label: 'TV Samsung',
      sku: 'TV-SAM',
      quantity: 2,
      unitHt: 1000,
      tvaRate: TvaRate.rate19,
    );

    expect(line.totalHt, 2000);
    expect(line.tvaAmount, 380);
    expect(line.totalTtc, 2380);
  });

  test('serializes and restores a production snapshot', () {
    final snapshot = AppSnapshot(
      company: const CompanyProfile(
        name: 'Technologia Plus SARL',
        taxId: '1234567/A/M/000',
        address: 'Sfax',
        city: 'Sfax',
        phone: '+216 74 000 000',
        email: 'contact@example.tn',
        logoSource: '',
        invoiceFooter: 'Merci.',
      ),
      warehouses: const [
        Warehouse(id: 'sfax', name: 'Magasin Sfax', city: 'Sfax'),
      ],
      categories: const [Category(id: 'cat-tv', name: 'TV')],
      products: const [
        Product(
          id: 'p1',
          name: 'TV Samsung',
          sku: 'TV-SAM',
          category: 'TV',
          purchaseHt: 800,
          saleHt: 1000,
          tvaRate: TvaRate.rate19,
          minStock: 2,
          serialTracked: true,
          stockByWarehouse: {'sfax': 3},
          serialsByWarehouse: {
            'sfax': ['SN-1', 'SN-2', 'SN-3'],
          },
          imageUrl: '',
        ),
      ],
      partners: const [
        Partner(
          id: 'c1',
          type: PartnerType.client,
          name: 'Client Test',
          taxId: '0987654/B/M/000',
          address: 'Tunis',
          phone: '+216 20 000 000',
          email: 'client@example.tn',
        ),
      ],
      documents: [
        BusinessDocument(
          id: 'd1',
          type: DocumentType.bl,
          number: 'BL-2026-0001',
          status: DocumentStatus.validated,
          partnerId: 'c1',
          partnerName: 'Client Test',
          partnerTaxId: '0987654/B/M/000',
          partnerAddress: 'Tunis',
          date: DateTime(2026, 4, 15),
          lines: const [
            DocumentLine(
              productId: 'p1',
              label: 'TV Samsung',
              sku: 'TV-SAM',
              quantity: 1,
              unitHt: 1000,
              tvaRate: TvaRate.rate19,
              serialNumbers: ['SN-1'],
            ),
          ],
          warehouseId: 'sfax',
        ),
      ],
      movements: [
        StockMovement(
          date: DateTime(2026, 4, 15),
          productId: 'p1',
          productName: 'TV Samsung',
          documentNumber: 'BL-2026-0001',
          direction: StockDirection.outbound,
          quantity: 1,
          warehouseId: 'sfax',
          serialNumbers: const ['SN-1'],
        ),
      ],
      sequences: const {DocumentType.bl: 2, DocumentType.facture: 1},
      auditEvents: [
        AuditEvent(
          id: 'a1',
          date: DateTime(2026, 4, 15),
          actor: 'Admin PME',
          action: 'Validation',
          target: 'BL-2026-0001',
          detail: 'Validé et verrouillé.',
        ),
      ],
    );

    final restored = AppSnapshot.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(snapshot.toJson())) as Map,
      ),
    );

    expect(restored.products.single.serialsIn('sfax'), [
      'SN-1',
      'SN-2',
      'SN-3',
    ]);
    expect(restored.documents.single.totalTtc, 1190);
    expect(restored.company.invoiceFooter, 'Merci.');
    expect(restored.sequences[DocumentType.bl], 2);
    expect(restored.auditEvents.single.target, 'BL-2026-0001');
  });
}
