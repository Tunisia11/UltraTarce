import '../../domain/app_models.dart';
import '../local/database/app_database.dart';
import '../local/database/mappers/category_mapper.dart';
import '../local/database/mappers/product_mapper.dart';
import 'app_repository.dart';

class CategoryRepository {
  CategoryRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Category> getCategories() =>
      List<Category>.from(_appRepository.snapshot.categories);

  Category? getDefaultCategory() {
    final categories = getCategories();
    final active = categories.where((category) => category.active).toList();
    if (active.isNotEmpty) return active.first;
    return categories.isEmpty ? null : categories.first;
  }

  bool hasDuplicateName(String name, {String? exceptId}) {
    final normalized = name.trim().toLowerCase();
    return getCategories().any(
      (category) =>
          category.id != exceptId &&
          category.name.trim().toLowerCase() == normalized,
    );
  }

  bool isUsed(String categoryName) {
    return _appRepository.snapshot.products.any(
      (product) => product.category == categoryName,
    );
  }

  AppSnapshot createCategory(Category category) {
    return _saveSnapshot(
      categories: [...getCategories(), category],
      status: 'Catégories sauvegardées.',
      write: (database) => database.categoryDao.upsertCategory(
        CategoryMapper.toCompanion(category, tenantId: _appRepository.tenantId),
      ),
    );
  }

  AppSnapshot updateCategory(Category category, {required String oldName}) {
    final categories = getCategories();
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.add(category);
    }
    final products = _appRepository.snapshot.products.map((product) {
      if (product.category != oldName) return product;
      return product.copyWith(category: category.name);
    }).toList();
    return _saveSnapshot(
      categories: categories,
      products: products,
      status: 'Catégories sauvegardées.',
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        await database.transaction(() async {
          await database.categoryDao.upsertCategory(
            CategoryMapper.toCompanion(category, tenantId: tenantId),
          );
          for (final product in products.where(
            (product) => product.category == category.name,
          )) {
            await database.productDao.upsertProduct(
              ProductMapper.toCompanion(product, tenantId: tenantId),
            );
          }
        });
      },
    );
  }

  AppSnapshot archiveCategory(Category category) {
    final categories = getCategories();
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index >= 0) {
      categories[index] = category.copyWith(active: false);
    }
    return _saveSnapshot(
      categories: categories,
      status: 'Catégorie désactivée.',
      write: (database) => database.categoryDao.archiveCategory(
        category.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot deleteCategory(Category category) {
    final categories = getCategories()
      ..removeWhere((item) => item.id == category.id);
    return _saveSnapshot(
      categories: categories,
      status: 'Catégorie supprimée.',
      write: (database) => database.categoryDao.deleteCategory(
        category.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot _saveSnapshot({
    required List<Category> categories,
    List<Product>? products,
    required String status,
    required Future<void> Function(AppDatabase database) write,
  }) {
    final snapshot = _appRepository.snapshot;
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: snapshot.company,
        warehouses: snapshot.warehouses,
        categories: categories,
        products: products ?? snapshot.products,
        partners: snapshot.partners,
        documents: snapshot.documents,
        movements: snapshot.movements,
        sequences: snapshot.sequences,
        auditEvents: snapshot.auditEvents,
      ),
      status: status,
      write: write,
    );
  }
}
