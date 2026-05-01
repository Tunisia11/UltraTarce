import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/category_repository.dart';
import '../../../domain/app_models.dart';

sealed class CategoryState {
  const CategoryState();
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  const CategoryLoaded({required this.categories});

  final List<Category> categories;

  Category? get defaultCategory {
    final active = categories.where((category) => category.active).toList();
    if (active.isNotEmpty) return active.first;
    return categories.isEmpty ? null : categories.first;
  }
}

class CategoryFailure extends CategoryState {
  const CategoryFailure(this.message);

  final String message;
}

class CategoryDeleteResult {
  const CategoryDeleteResult({required this.snapshot, required this.archived});

  final AppSnapshot snapshot;
  final bool archived;
}

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._categoryRepository) : super(const CategoryInitial());

  final CategoryRepository _categoryRepository;

  List<Category> get categories => _categoryRepository.getCategories();

  void loadCategories() {
    emit(const CategoryLoading());
    try {
      emit(CategoryLoaded(categories: _categoryRepository.getCategories()));
    } catch (error) {
      emit(CategoryFailure(error.toString()));
    }
  }

  bool hasDuplicateName(String name, {String? exceptId}) {
    return _categoryRepository.hasDuplicateName(name, exceptId: exceptId);
  }

  AppSnapshot createCategory(Category category) {
    final snapshot = _categoryRepository.createCategory(category);
    loadCategories();
    return snapshot;
  }

  AppSnapshot updateCategory(Category category, {required String oldName}) {
    final snapshot = _categoryRepository.updateCategory(
      category,
      oldName: oldName,
    );
    loadCategories();
    return snapshot;
  }

  AppSnapshot archiveCategory(Category category) {
    final snapshot = _categoryRepository.archiveCategory(category);
    loadCategories();
    return snapshot;
  }

  CategoryDeleteResult deleteOrArchiveCategory(Category category) {
    final shouldArchive = _categoryRepository.isUsed(category.name);
    final snapshot = shouldArchive
        ? _categoryRepository.archiveCategory(category)
        : _categoryRepository.deleteCategory(category);
    loadCategories();
    return CategoryDeleteResult(snapshot: snapshot, archived: shouldArchive);
  }
}
