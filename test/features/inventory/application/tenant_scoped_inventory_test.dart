import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/app_config.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/core/result/app_result.dart';
import 'package:ultra_trace/data/repositories/audit_repository.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/products_cubit.dart';
import 'package:ultra_trace/features/inventory/application/sales_cubit.dart';

import '../../../data/repositories/drift_repository_test_helpers.dart' as drift;
import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('dev bypass resolves the local demo tenant', () {
    final context = TenantContext.current(config: AppConfig.devBypass());

    expect(context.selectedTenantId, TenantContext.devBypassTenantId);
    expect(context.isDevBypassTenantActive, isTrue);
  });

  test(
    'ProductsCubit createProductResult reports persistence failure',
    () async {
      final harness = await drift.createDriftRepositoryHarness();
      final cubit = ProductsCubit(
        ProductRepository(harness.appRepository),
        StockRepository(harness.appRepository),
        AuditRepository(harness.appRepository),
      );
      addTearDown(cubit.close);
      await harness.database.close();

      final result = await cubit.createProductResult(drift.testProduct());

      expect(result, isA<AppFailure<AppSnapshot>>());
      expect(cubit.state.lastMutationResult, isA<AppFailure<AppSnapshot>>());
    },
  );

  test('SalesCubit createSaleResult reports persistence failure', () async {
    final product = drift.testProduct(stock: 10);
    final client = drift.testPartner();
    final harness = await drift.createDriftRepositoryHarness(
      snapshot: drift.testSnapshot(products: [product], partners: [client]),
    );
    final cubit = SalesCubit(
      DocumentRepository(harness.appRepository),
      StockRepository(harness.appRepository),
      AuditRepository(harness.appRepository),
    );
    addTearDown(cubit.close);
    cubit.startSale(type: DocumentType.facture);
    cubit.addLine(product, quantity: 1);
    await harness.database.close();

    final result = await cubit.createSaleResult(
      id: 'sale-fail',
      number: 'FAC-2026-FAIL',
      client: client,
      company: harness.appRepository.snapshot.company,
      date: DateTime(2026, 5, 1),
      warehouseId: 'wh-main',
    );

    expect(result, isA<AppFailure<AppSnapshot>>());
    expect(cubit.state.lastMutationResult, isA<AppFailure<AppSnapshot>>());
  });

  test(
    'SalesCubit addPaymentResult reports success through existing API',
    () async {
      final invoice = testInvoice();
      final repositories = createTestRepositories(
        snapshot: testSnapshot(documents: [invoice]),
      );
      final cubit = SalesCubit(
        repositories.documentRepository,
        repositories.stockRepository,
        repositories.auditRepository,
      );
      addTearDown(cubit.close);

      final result = await cubit.addPaymentResult(
        document: invoice,
        documents: repositories.documentRepository.getAll(),
        payment: PaymentEntry(
          id: 'pay-result',
          date: DateTime(2026, 5, 1),
          amount: invoice.netToPay,
          method: PaymentMethod.cash,
        ),
        formatMoney: testFormatMoney,
      );

      expect(result, isA<AppSuccess<AppSnapshot>>());
      expect(cubit.state.lastMutationResult, isA<AppSuccess<AppSnapshot>>());
    },
  );
}
