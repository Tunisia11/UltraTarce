/// Describes the status of local business data for a given tenant.
class LocalTenantDataStatus {
  const LocalTenantDataStatus({
    this.productCount = 0,
    this.partnerCount = 0,
    this.documentCount = 0,
    this.stockMovementCount = 0,
    this.warehouseCount = 0,
    this.categoryCount = 0,
  });

  final int productCount;
  final int partnerCount;
  final int documentCount;
  final int stockMovementCount;
  final int warehouseCount;
  final int categoryCount;

  bool get isEmpty =>
      productCount == 0 &&
      partnerCount == 0 &&
      documentCount == 0 &&
      stockMovementCount == 0 &&
      warehouseCount == 0 &&
      categoryCount == 0;

  int get totalRows =>
      productCount +
      partnerCount +
      documentCount +
      stockMovementCount +
      warehouseCount +
      categoryCount;
}
