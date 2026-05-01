import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/stock_mutation_service.dart';

void main() {
  test('low stock detection uses active tracked products at threshold', () {
    final products = [
      _product(stockByWarehouse: const {'main': 2}, minStock: 2),
      _product(id: 'p2', stockByWarehouse: const {'main': 10}, minStock: 2),
    ];

    expect(StockMutationService.lowStockProducts(products).single.id, 'p1');
  });

  test('sale decreases stock and creates outbound movement', () {
    final result = StockMutationService.applyOutboundDocument(
      products: [
        _product(stockByWarehouse: const {'main': 5}),
      ],
      document: _document(DocumentType.facture),
      date: DateTime(2026, 5, 1),
    );

    expect(result.products.single.stockIn('main'), 3);
    expect(result.movements.single.direction, StockDirection.outbound);
    expect(result.movements.single.quantity, 2);
  });

  test('initial stock creates inbound movement', () {
    final outcome = StockMutationService.applyInitialStock(
      products: [
        _product(stockByWarehouse: const {'main': 0}),
      ],
      productId: 'p1',
      warehouseId: 'main',
      quantity: 4,
      movementNumber: 'INI-2026-0001',
      date: DateTime(2026, 5, 1),
      serialGenerator: (sku, index) => 'SN-$sku-$index',
    );

    expect(outcome.isSuccess, isTrue);
    expect(outcome.result!.products.single.stockIn('main'), 4);
    expect(outcome.result!.movements.single.direction, StockDirection.inbound);
    expect(outcome.result!.movements.single.documentNumber, 'INI-2026-0001');
  });
}

Product _product({
  String id = 'p1',
  required Map<String, int> stockByWarehouse,
  int minStock = 1,
}) {
  return Product(
    id: id,
    name: 'Article',
    sku: 'ART',
    category: 'Cat',
    purchaseHt: 50,
    saleHt: 100,
    tvaRate: TvaRate.rate19,
    minStock: minStock,
    serialTracked: false,
    stockByWarehouse: stockByWarehouse,
    serialsByWarehouse: const {},
    imageUrl: '',
  );
}

BusinessDocument _document(DocumentType type) {
  return BusinessDocument(
    id: 'doc-1',
    type: type,
    number: 'FAC-2026-0001',
    status: DocumentStatus.validated,
    partnerId: 'c1',
    partnerName: 'Client',
    partnerTaxId: '',
    partnerAddress: '',
    date: DateTime(2026, 5, 1),
    lines: const [
      DocumentLine(
        productId: 'p1',
        label: 'Article',
        sku: 'ART',
        quantity: 2,
        unitHt: 100,
        tvaRate: TvaRate.rate19,
      ),
    ],
    warehouseId: 'main',
  );
}
