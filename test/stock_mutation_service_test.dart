import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/stock_mutation_service.dart';

void main() {
  group('StockMutationService document stock', () {
    test(
      'outbound document decreases stock, removes serials, and records movement',
      () {
        final result = StockMutationService.applyOutboundDocument(
          products: [_serialProduct()],
          document: _document(
            type: DocumentType.facture,
            number: 'FAC-2026-0001',
            lines: [
              _line(quantity: 1, serialNumbers: ['SN-1']),
            ],
          ),
          date: DateTime(2026, 4, 22),
        );

        final product = result.products.single;
        expect(product.stockIn('main'), 1);
        expect(product.serialsIn('main'), ['SN-2']);
        expect(result.lines.single.serialNumbers, ['SN-1']);
        expect(result.movements.single.direction, StockDirection.outbound);
        expect(result.movements.single.documentNumber, 'FAC-2026-0001');
      },
    );

    test('inbound document increases stock and generates missing serials', () {
      final result = StockMutationService.applyInboundDocument(
        products: [_serialProduct()],
        document: _document(
          type: DocumentType.creditNote,
          number: 'AVR-2026-0001',
          lines: [_line(quantity: 1)],
        ),
        date: DateTime(2026, 4, 22),
        serialGenerator: _serialGenerator,
      );

      final product = result.products.single;
      expect(product.stockIn('main'), 3);
      expect(product.serialsIn('main'), ['SN-1', 'SN-2', 'GEN-TV-SAM-0']);
      expect(result.lines.single.serialNumbers, ['GEN-TV-SAM-0']);
      expect(result.movements.single.direction, StockDirection.inbound);
    });

    test('reversing outbound document restores stock and serials', () {
      final soldProduct = _serialProduct(
        stockByWarehouse: const {'main': 1},
        serialsByWarehouse: const {
          'main': ['SN-2'],
        },
      );
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0002',
        lines: [
          _line(quantity: 1, serialNumbers: ['SN-1']),
        ],
      );

      final outcome = StockMutationService.reverseDocument(
        products: [soldProduct],
        document: invoice,
        date: DateTime(2026, 4, 22),
        warehouseNameById: (_) => 'Magasin principal',
        serialGenerator: _serialGenerator,
      );

      expect(outcome.isSuccess, isTrue);
      final result = outcome.result!;
      expect(result.products.single.stockIn('main'), 2);
      expect(result.products.single.serialsIn('main'), ['SN-2', 'SN-1']);
      expect(result.movements.single.documentNumber, 'ANN-FAC-2026-0002');
      expect(result.movements.single.direction, StockDirection.inbound);
    });

    test(
      'reversing inbound document is blocked when its serial already moved',
      () {
        final product = _serialProduct(
          stockByWarehouse: const {'main': 1},
          serialsByWarehouse: const {
            'main': ['SN-9'],
          },
        );
        final entry = _document(
          type: DocumentType.stockEntry,
          number: 'BE-2026-0001',
          lines: [
            _line(quantity: 1, serialNumbers: ['SN-1']),
          ],
        );

        final outcome = StockMutationService.reverseDocument(
          products: [product],
          document: entry,
          date: DateTime(2026, 4, 22),
          warehouseNameById: (_) => 'Magasin principal',
          serialGenerator: _serialGenerator,
        );

        expect(outcome.isSuccess, isFalse);
        expect(outcome.errorMessage, contains('Annulation impossible'));
        expect(outcome.errorMessage, contains('indisponible'));
      },
    );
  });

  group('StockMutationService operations', () {
    test('transfer moves quantity, serials, and creates paired movements', () {
      final outcome = StockMutationService.applyTransfer(
        products: [
          _serialProduct(stockByWarehouse: const {'main': 2, 'annexe': 0}),
        ],
        productId: 'p1',
        fromWarehouseId: 'main',
        toWarehouseId: 'annexe',
        quantity: 1,
        serialNumbers: const ['SN-1'],
        movementNumber: 'TRF-2026-0001',
        date: DateTime(2026, 4, 22),
      );

      expect(outcome.isSuccess, isTrue);
      final product = outcome.result!.products.single;
      expect(product.stockIn('main'), 1);
      expect(product.stockIn('annexe'), 1);
      expect(product.serialsIn('main'), ['SN-2']);
      expect(product.serialsIn('annexe'), ['SN-1']);
      expect(outcome.result!.movements.map((movement) => movement.direction), [
        StockDirection.outbound,
        StockDirection.inbound,
      ]);
      expect(
        outcome.result!.movements.map((movement) => movement.documentNumber),
        ['TRF-2026-0001', 'TRF-2026-0001'],
      );
    });

    test('adjustment validates outbound serial availability', () {
      final outcome = StockMutationService.applyAdjustment(
        products: [_serialProduct()],
        productId: 'p1',
        warehouseId: 'main',
        direction: StockDirection.outbound,
        quantity: 1,
        serialNumbers: const ['SN-9'],
        movementNumber: 'AJU-2026-0001',
        date: DateTime(2026, 4, 22),
        serialGenerator: _serialGenerator,
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.errorMessage, contains('indisponibles'));
    });

    test('adjustment inbound generates serials and records movement', () {
      final outcome = StockMutationService.applyAdjustment(
        products: [_serialProduct()],
        productId: 'p1',
        warehouseId: 'main',
        direction: StockDirection.inbound,
        quantity: 1,
        serialNumbers: const [],
        movementNumber: 'AJU-2026-0002',
        date: DateTime(2026, 4, 22),
        serialGenerator: _serialGenerator,
      );

      expect(outcome.isSuccess, isTrue);
      final result = outcome.result!;
      expect(result.products.single.stockIn('main'), 3);
      expect(result.products.single.serialsIn('main').last, 'GEN-TV-SAM-0');
      expect(result.movements.single.documentNumber, 'AJU-2026-0002');
      expect(result.movements.single.direction, StockDirection.inbound);
    });
  });
}

String _serialGenerator(String sku, int index) => 'GEN-$sku-$index';

Product _serialProduct({
  Map<String, int> stockByWarehouse = const {'main': 2},
  Map<String, List<String>> serialsByWarehouse = const {
    'main': ['SN-1', 'SN-2'],
  },
}) {
  return Product(
    id: 'p1',
    name: 'TV Samsung',
    sku: 'TV-SAM',
    category: 'TV',
    purchaseHt: 800,
    saleHt: 1000,
    tvaRate: TvaRate.rate19,
    minStock: 1,
    serialTracked: true,
    stockByWarehouse: stockByWarehouse,
    serialsByWarehouse: serialsByWarehouse,
    imageUrl: '',
  );
}

DocumentLine _line({int quantity = 1, List<String> serialNumbers = const []}) {
  return DocumentLine(
    productId: 'p1',
    label: 'TV Samsung',
    sku: 'TV-SAM',
    quantity: quantity,
    unitHt: 1000,
    tvaRate: TvaRate.rate19,
    serialNumbers: serialNumbers,
  );
}

BusinessDocument _document({
  required DocumentType type,
  required String number,
  required List<DocumentLine> lines,
}) {
  return BusinessDocument(
    id: number,
    type: type,
    number: number,
    status: DocumentStatus.validated,
    partnerId: 'c1',
    partnerName: 'Client Test',
    partnerTaxId: '1234567/A/M/000',
    partnerAddress: 'Tunis',
    date: DateTime(2026, 4, 22),
    lines: lines,
    warehouseId: 'main',
  );
}
