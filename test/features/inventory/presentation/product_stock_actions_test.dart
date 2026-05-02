import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/category_cubit.dart';
import 'package:ultra_trace/features/inventory/application/products_cubit.dart';
import 'package:ultra_trace/features/inventory/application/warehouse_cubit.dart';
import 'package:ultra_trace/features/inventory/presentation/products/product_form_page.dart';

import '../application/inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  Widget buildTestWidget({
    required ProductsCubit productsCubit,
    required WarehouseCubit warehouseCubit,
    required CategoryCubit categoryCubit,
    Product? product,
  }) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: productsCubit),
          BlocProvider.value(value: warehouseCubit),
          BlocProvider.value(value: categoryCubit),
        ],
        child: ProductFormPage(product: product, tenantId: 'test-tenant'),
      ),
    );
  }

  testWidgets('New product form shows Stock initial field', (tester) async {
    final repos = createTestRepositories();
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    categoryCubit.loadCategories();
    warehouseCubit.loadWarehouses();
    productsCubit.loadProducts();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
      ),
    );

    expect(find.text('Image produit'), findsOneWidget);
    expect(find.text('Informations générales'), findsOneWidget);
    expect(find.text('Prix et taxes'), findsOneWidget);
    expect(find.text('Stock et inventaire'), findsOneWidget);
    expect(find.text('Détails supplémentaires'), findsOneWidget);
    expect(find.textContaining('PNG, JPG ou WEBP — max 1 Mo'), findsOneWidget);
    expect(find.text('Stock initial'), findsOneWidget);
    expect(find.text('Dépôt de départ'), findsOneWidget);
  });

  testWidgets(
    'Existing product form does not show Stock initial field but shows Stock actuel',
    (tester) async {
      final product = testProduct(stock: 10);
      final repos = createTestRepositories(
        snapshot: testSnapshot(products: [product]),
      );
      final productsCubit = ProductsCubit(
        repos.productRepository,
        repos.stockRepository,
        repos.auditRepository,
      );
      final warehouseCubit = WarehouseCubit(
        repos.warehouseRepository,
        repos.auditRepository,
      );
      final categoryCubit = CategoryCubit(repos.categoryRepository);

      await tester.pumpWidget(
        buildTestWidget(
          productsCubit: productsCubit,
          warehouseCubit: warehouseCubit,
          categoryCubit: categoryCubit,
          product: product,
        ),
      );

      expect(find.text('Stock initial'), findsNothing);
      expect(find.text('Stock actuel'), findsOneWidget);
      expect(find.text('Stock Total'), findsOneWidget);
      expect(find.text('Ajuster stock'), findsOneWidget);
      expect(find.text('Entrée stock'), findsOneWidget);
      expect(find.text('Sortie stock'), findsOneWidget);
      expect(find.text('Transférer'), findsOneWidget);
      expect(find.text('Historique stock'), findsOneWidget);
      expect(find.text('10').first, findsOneWidget);
    },
  );

  testWidgets('Entrée stock increases stock and creates movement', (
    tester,
  ) async {
    final product = testProduct(stock: 10);
    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Entrée stock'));
    await tester.tap(find.text('Entrée stock'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité'), '5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motif (obligatoire)'),
      'Achat test',
    );
    await tester.tap(find.text('Confirmer entrée'));
    await tester.pumpAndSettle();

    // Check if UI updated
    expect(find.text('15').first, findsOneWidget);

    // Verify cubit state
    final updatedProduct = productsCubit.state.products.firstWhere(
      (p) => p.id == product.id,
    );
    expect(updatedProduct.totalStock, 15);

    // Verify movement
    final movements = repos.stockRepository.movementsForProduct(product.id);
    expect(movements.length, 1);
    expect(movements.first.quantity, 5);
    expect(movements.first.direction, StockDirection.inbound);
    expect(movements.first.reason, 'Achat test');
  });

  testWidgets('Sortie stock decreases stock and creates movement', (
    tester,
  ) async {
    final product = testProduct(stock: 10);
    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Sortie stock'));
    await tester.tap(find.text('Sortie stock'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité'), '3');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motif (obligatoire)'),
      'Dommage',
    );
    await tester.tap(find.text('Confirmer sortie'));
    await tester.pumpAndSettle();

    expect(find.text('7').first, findsOneWidget);

    final movements = repos.stockRepository.movementsForProduct(product.id);
    expect(movements.length, 1);
    expect(movements.first.quantity, 3);
    expect(movements.first.direction, StockDirection.outbound);
  });

  testWidgets('Sortie stock blocks negative stock', (tester) async {
    final product = testProduct(stock: 10);
    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Sortie stock'));
    await tester.tap(find.text('Sortie stock'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantité'),
      '11',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Motif (obligatoire)'),
      'Test trop',
    );
    await tester.tap(find.text('Confirmer sortie'));
    await tester.pumpAndSettle();

    expect(find.text('Stock insuffisant'), findsOneWidget);
    expect(find.text('10').first, findsOneWidget);
  });

  testWidgets('Transfert stock moves stock between warehouses', (tester) async {
    final warehouse2 = const Warehouse(
      id: 'wh2',
      name: 'Dépôt 2',
      city: 'Sousse',
    );
    final product = testProduct(stock: 10);
    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );

    // Add second warehouse to snapshot manually since testSnapshot only adds one
    final snapshot = repos.appRepository.snapshot;
    repos.appRepository.setSnapshot(
      snapshot.copyWith(warehouses: [...snapshot.warehouses, warehouse2]),
    );

    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Transférer'));
    await tester.tap(find.text('Transférer'));
    await tester.pumpAndSettle();

    // Select second warehouse as destination
    final destDropdown = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Dépôt destination',
    );
    await tester.tap(destDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dépôt 2').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité'), '4');
    await tester.tap(find.text('Confirmer transfert'));
    await tester.pumpAndSettle();

    // Total stock remains same
    expect(find.text('10').first, findsOneWidget);

    final updatedProduct = productsCubit.state.products.firstWhere(
      (p) => p.id == product.id,
    );
    expect(updatedProduct.stockIn(testWarehouseId), 6);
    expect(updatedProduct.stockIn('wh2'), 4);

    final movements = repos.stockRepository.movementsForProduct(product.id);
    expect(movements.length, 2); // Out and In
  });

  testWidgets('Transfert blocks same source/destination', (tester) async {
    final product = testProduct(stock: 10);
    final warehouse2 = const Warehouse(
      id: 'wh2',
      name: 'Dépôt 2',
      city: 'Sousse',
    );
    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );

    // Add second warehouse
    final snapshot = repos.appRepository.snapshot;
    repos.appRepository.setSnapshot(
      snapshot.copyWith(warehouses: [...snapshot.warehouses, warehouse2]),
    );

    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Transférer'));
    await tester.tap(find.text('Transférer'));
    await tester.pumpAndSettle();

    // Select same warehouse as destination (Source is wh-main by default, initial Dest is wh2)
    final destDropdown = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Dépôt destination',
    );
    await tester.tap(destDropdown);
    await tester.pumpAndSettle();

    // Tap the 'Dépôt principal' option in the list
    await tester.tap(find.text('Dépôt principal').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité'), '4');
    await tester.ensureVisible(find.text('Confirmer transfert'));
    await tester.tap(find.text('Confirmer transfert'));
    await tester.pumpAndSettle();

    // Dialog should still be open because validation failed
    expect(find.text('Confirmer transfert'), findsOneWidget);
    expect(find.textContaining('doivent être différents'), findsOneWidget);
  });

  testWidgets('Stock history shows recent movements and document link', (
    tester,
  ) async {
    final product = testProduct(stock: 10);
    final movement = StockMovement(
      productId: product.id,
      productName: product.name,
      warehouseId: testWarehouseId,
      date: DateTime.now(),
      quantity: 5,
      direction: StockDirection.inbound,
      reason: 'Vente test',
      documentNumber: 'FAC-2026-0001',
    );

    final repos = createTestRepositories(
      snapshot: testSnapshot(products: [product], movements: [movement]),
    );
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);

    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      buildTestWidget(
        productsCubit: productsCubit,
        warehouseCubit: warehouseCubit,
        categoryCubit: categoryCubit,
        product: product,
      ),
    );

    await tester.ensureVisible(find.text('Historique stock').first);
    expect(find.text('+5 · Vente test'), findsOneWidget);
    expect(find.textContaining('Doc: FAC-2026-0001'), findsOneWidget);
  });
}
