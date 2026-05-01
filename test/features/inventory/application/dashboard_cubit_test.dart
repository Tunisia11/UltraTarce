import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/dashboard_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('DashboardCubit calculates metrics from repository data', () {
    final product = testProduct(stock: 1, minStock: 2);
    final invoice = testInvoice(product: product, date: DateTime.now());
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product], documents: [invoice]),
    );
    final cubit = DashboardCubit(repositories.appRepository);
    addTearDown(cubit.close);

    cubit.loadDashboard();

    expect(cubit.state.dailySales, invoice.netToPay);
    expect(cubit.state.monthlySales, invoice.netToPay);
    expect(cubit.state.unpaidAmount, invoice.netToPay);
    expect(cubit.state.lowStockCount, 1);
    expect(cubit.state.bestSellers.single.key.id, product.id);
    expect(cubit.state.bestSellers.single.value, 1);
  });
}
