import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/documents_cubit.dart';
import 'package:ultra_trace/features/inventory/application/products_cubit.dart';
import 'package:ultra_trace/features/inventory/application/stock_cubit.dart';
import 'package:ultra_trace/features/inventory/application/warehouse_cubit.dart';
import 'package:ultra_trace/features/inventory/presentation/sales/bon_sortie_form_page.dart';

import '../application/inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  testWidgets('Bon Sortie form shows source, camion, and chauffeur fields', (
    tester,
  ) async {
    final product = testProduct(stock: 8);
    final repos = createTestRepositories(
      snapshot: _snapshotWithMobileWarehouse(product),
    );
    final documentsCubit = DocumentsCubit(
      repos.documentRepository,
      repos.auditRepository,
    );
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    )..loadProducts();
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    )..loadWarehouses();
    final stockCubit = StockCubit(repos.stockRepository, repos.auditRepository)
      ..loadStockOverview();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: documentsCubit),
            BlocProvider.value(value: productsCubit),
            BlocProvider.value(value: warehouseCubit),
            BlocProvider.value(value: stockCubit),
          ],
          child: BonSortieFormPage(
            company: testCompany(),
            nextNumber: 'BS-2026-0001',
          ),
        ),
      ),
    );

    expect(find.text('Préparer une sortie camion'), findsWidgets);
    expect(find.text('Dépôt source'), findsOneWidget);
    expect(find.text('Camion / unité mobile'), findsOneWidget);
    expect(find.text('Chauffeur'), findsOneWidget);
    expect(find.text('Matricule véhicule'), findsOneWidget);
    expect(find.text('Destination / tournée'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Produits à charger'), findsOneWidget);
  });
}

AppSnapshot _snapshotWithMobileWarehouse(Product product) {
  return AppSnapshot(
    company: testCompany(),
    warehouses: const [
      Warehouse(id: testWarehouseId, name: 'Dépôt principal', city: 'Tunis'),
      Warehouse(
        id: 'truck-1',
        name: 'Camion 1',
        city: 'Tunis',
        code: 'CAM-1',
        type: 'mobile',
      ),
    ],
    categories: const [Category(id: 'cat-main', name: 'Général')],
    products: [product],
    partners: const [],
    documents: const [],
    movements: const [],
    sequences: const {DocumentType.bonSortie: 1},
    auditEvents: const [],
  );
}
