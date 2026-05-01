import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/app_repository.dart';
import '../../../domain/app_models.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit(this._appRepository) : super(const InventoryInitial());

  final AppRepository _appRepository;

  AppRepository get repository => _appRepository;

  Future<void> loadInitialData() async {
    emit(const InventoryLoading());
    try {
      final result = await _appRepository.loadAsync();
      emit(
        InventoryLoaded(
          snapshot: result.snapshot,
          storageStatus: _appRepository.storageStatus,
          lastSavedAt: _appRepository.lastSavedAt,
        ),
      );
    } catch (error) {
      emit(InventoryFailure(error.toString()));
    }
  }

  void setSnapshot(
    AppSnapshot snapshot, {
    required String storageStatus,
    DateTime? lastSavedAt,
  }) {
    _appRepository.setSnapshot(
      snapshot,
      status: storageStatus,
      savedAt: lastSavedAt,
    );
    emit(
      InventoryLoaded(
        snapshot: snapshot,
        storageStatus: _appRepository.storageStatus,
        lastSavedAt: _appRepository.lastSavedAt,
      ),
    );
  }

  void persistSnapshot(AppSnapshot snapshot, {required String status}) {
    try {
      _appRepository.save(snapshot, status: status);
      emit(
        InventoryLoaded(
          snapshot: snapshot,
          storageStatus: _appRepository.storageStatus,
          lastSavedAt: _appRepository.lastSavedAt,
        ),
      );
    } catch (error) {
      emit(InventoryFailure(error.toString()));
    }
  }

  void refresh() {
    final snapshot = _appRepository.snapshot;
    emit(
      InventoryLoaded(
        snapshot: snapshot,
        storageStatus: _appRepository.storageStatus,
        lastSavedAt: _appRepository.lastSavedAt,
      ),
    );
  }
}
