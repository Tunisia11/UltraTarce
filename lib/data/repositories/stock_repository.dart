import '../../domain/app_models.dart';
import '../../core/result/app_result.dart';
import '../../domain/services/stock_mutation_service.dart';
import '../local/database/mappers/product_mapper.dart';
import '../local/database/mappers/stock_mapper.dart';
import 'app_repository.dart';

class StockRepository {
  StockRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Product> get products =>
      List<Product>.from(_appRepository.snapshot.products);

  List<StockMovement> get movements =>
      List<StockMovement>.from(_appRepository.snapshot.movements);

  List<StockMovement> movementsForProduct(String productId) {
    return movements
        .where((movement) => movement.productId == productId)
        .toList();
  }

  Future<AppResult<void>> flushPendingWritesResult() {
    return _appRepository.flushPendingMutationResult();
  }

  AppSnapshot applyStockMutation(
    StockMutationResult result, {
    required String status,
  }) {
    final snapshot = _appRepository.snapshot;
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: snapshot.company,
        warehouses: snapshot.warehouses,
        categories: snapshot.categories,
        products: result.products,
        partners: snapshot.partners,
        documents: snapshot.documents,
        movements: [...result.movements, ...snapshot.movements],
        sequences: snapshot.sequences,
        auditEvents: snapshot.auditEvents,
      ),
      status: status,
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        await database.transaction(() async {
          for (final product in result.products) {
            await database.productDao.upsertProduct(
              ProductMapper.toCompanion(product, tenantId: tenantId),
            );
          }
          final existingMovementCount = snapshot.movements.length;
          for (var index = 0; index < result.movements.length; index++) {
            await database.stockDao.addMovement(
              StockMapper.toCompanion(
                result.movements[index],
                index: existingMovementCount + index,
                tenantId: tenantId,
              ),
            );
          }
        });
      },
    );
  }
}
