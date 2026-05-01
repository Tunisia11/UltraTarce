import '../../../domain/app_models.dart';

sealed class InventoryState {
  const InventoryState();
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.snapshot,
    required this.storageStatus,
    this.lastSavedAt,
  });

  final AppSnapshot snapshot;
  final String storageStatus;
  final DateTime? lastSavedAt;
}

class InventoryFailure extends InventoryState {
  const InventoryFailure(this.message);

  final String message;
}
