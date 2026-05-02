import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/sync/local_tenant_data_status.dart';

void main() {
  group('LocalTenantDataStatus', () {
    test('isEmpty returns true when all counts are zero', () {
      const status = LocalTenantDataStatus();
      expect(status.isEmpty, isTrue);
      expect(status.totalRows, 0);
    });

    test('isEmpty returns false when any count is non-zero', () {
      const status1 = LocalTenantDataStatus(productCount: 1);
      const status2 = LocalTenantDataStatus(partnerCount: 1);
      const status3 = LocalTenantDataStatus(documentCount: 1);
      const status4 = LocalTenantDataStatus(stockMovementCount: 1);
      const status5 = LocalTenantDataStatus(warehouseCount: 1);
      const status6 = LocalTenantDataStatus(categoryCount: 1);

      expect(status1.isEmpty, isFalse);
      expect(status2.isEmpty, isFalse);
      expect(status3.isEmpty, isFalse);
      expect(status4.isEmpty, isFalse);
      expect(status5.isEmpty, isFalse);
      expect(status6.isEmpty, isFalse);
    });

    test('totalRows calculates correctly', () {
      const status = LocalTenantDataStatus(
        productCount: 2,
        partnerCount: 3,
        documentCount: 1,
        stockMovementCount: 4,
        warehouseCount: 1,
        categoryCount: 5,
      );

      expect(status.totalRows, 16);
      expect(status.isEmpty, isFalse);
    });
  });
}
