import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/category_cubit.dart';
import 'package:ultra_trace/features/inventory/application/products_cubit.dart';
import 'package:ultra_trace/features/inventory/application/warehouse_cubit.dart';
import 'package:ultra_trace/features/inventory/presentation/products/product_form_page.dart';

import '../application/inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  testWidgets('ProductFormPage can access inherited providers in new route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repos = createTestRepositories();
    final productsCubit = ProductsCubit(
      repos.productRepository,
      repos.stockRepository,
      repos.auditRepository,
    );
    final categoryCubit = CategoryCubit(repos.categoryRepository);
    final warehouseCubit = WarehouseCubit(
      repos.warehouseRepository,
      repos.auditRepository,
    );

    // Initial load
    categoryCubit.loadCategories();
    warehouseCubit.loadWarehouses();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider<ProductsCubit>.value(value: productsCubit),
                        BlocProvider<CategoryCubit>.value(value: categoryCubit),
                        BlocProvider<WarehouseCubit>.value(
                          value: warehouseCubit,
                        ),
                      ],
                      child: const ProductFormPage(),
                    ),
                  ),
                );
              },
              child: const Text('Open Form'),
            ),
          ),
        ),
      ),
    );

    // Click to open form
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    // Verify form is open and providers are accessible
    expect(find.byType(ProductFormPage), findsOneWidget);

    // Check if dropdowns populated (requires providers to work)
    expect(find.text('Général'), findsOneWidget); // Default category
    expect(find.text('Dépôt principal'), findsOneWidget); // Default warehouse
  });
}
