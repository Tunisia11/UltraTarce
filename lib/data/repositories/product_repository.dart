import '../../domain/app_models.dart';
import '../../core/result/app_result.dart';
import '../local/database/app_database.dart';
import '../local/database/mappers/product_mapper.dart';
import 'app_repository.dart';

class ProductRepository {
  ProductRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Product> getAll() =>
      List<Product>.from(_appRepository.snapshot.products);

  List<Product> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();
    return getAll()
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalized) ||
              product.sku.toLowerCase().contains(normalized) ||
              product.category.toLowerCase().contains(normalized) ||
              product.brand.toLowerCase().contains(normalized) ||
              (product.barcode?.toLowerCase().contains(normalized) ?? false),
        )
        .toList();
  }

  bool isUsed(String productId) {
    return _appRepository.snapshot.documents.any(
      (document) => document.lines.any((line) => line.productId == productId),
    );
  }

  Future<AppResult<void>> flushPendingWritesResult() {
    return _appRepository.flushPendingMutationResult();
  }

  AppSnapshot saveAll(List<Product> products, {required String status}) {
    final previous = _appRepository.snapshot;
    final updated = _snapshotWithProducts(previous, products);
    return _appRepository.commitDaoMutation(
      updated,
      status: status,
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        final previousIds = previous.products
            .map((product) => product.id)
            .toSet();
        final nextIds = products.map((product) => product.id).toSet();
        await database.transaction(() async {
          for (final product in products) {
            await database.productDao.upsertProduct(
              ProductMapper.toCompanion(product, tenantId: tenantId),
            );
          }
          for (final deletedId in previousIds.difference(nextIds)) {
            await database.productDao.deleteProduct(
              deletedId,
              tenantId: tenantId,
            );
          }
        });
      },
    );
  }

  AppSnapshot upsert(Product product, {required String status}) {
    final products = getAll();
    final index = products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    return _commitProductList(
      products,
      status: status,
      write: (database) => database.productDao.upsertProduct(
        ProductMapper.toCompanion(product, tenantId: _appRepository.tenantId),
      ),
    );
  }

  AppSnapshot archive(Product product, {required String status}) {
    return upsert(product.copyWith(active: false), status: status);
  }

  AppSnapshot delete(Product product, {required String status}) {
    final products = getAll()..removeWhere((item) => item.id == product.id);
    return _commitProductList(
      products,
      status: status,
      write: (database) => database.productDao.deleteProduct(
        product.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot _commitProductList(
    List<Product> products, {
    required String status,
    required Future<void> Function(AppDatabase database) write,
  }) {
    final updated = _snapshotWithProducts(_appRepository.snapshot, products);
    return _appRepository.commitDaoMutation(
      updated,
      status: status,
      write: (database) => write(database),
    );
  }

  AppSnapshot _snapshotWithProducts(
    AppSnapshot snapshot,
    List<Product> products,
  ) {
    return AppSnapshot(
      company: snapshot.company,
      warehouses: snapshot.warehouses,
      categories: snapshot.categories,
      products: products,
      partners: snapshot.partners,
      documents: snapshot.documents,
      movements: snapshot.movements,
      sequences: snapshot.sequences,
      auditEvents: snapshot.auditEvents,
    );
  }
}
