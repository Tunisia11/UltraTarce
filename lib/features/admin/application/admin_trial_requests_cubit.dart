import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_trial_request_repository.dart';

abstract class AdminTrialRequestsState {}

class AdminTrialRequestsInitial extends AdminTrialRequestsState {}

class AdminTrialRequestsLoading extends AdminTrialRequestsState {}

class AdminTrialRequestsLoaded extends AdminTrialRequestsState {
  AdminTrialRequestsLoaded(this.requests);
  final List<TrialRequest> requests;
}

class AdminTrialRequestsError extends AdminTrialRequestsState {
  AdminTrialRequestsError(this.message);
  final String message;
}

class AdminTrialRequestsCubit extends Cubit<AdminTrialRequestsState> {
  AdminTrialRequestsCubit(this._repository)
    : super(AdminTrialRequestsInitial());

  final AdminTrialRequestRepository? _repository;

  Future<void> loadRequests() async {
    emit(AdminTrialRequestsLoading());
    final repository = _repository;
    if (repository == null) {
      emit(AdminTrialRequestsLoaded(const []));
      return;
    }
    try {
      final requests = await repository.getTrialRequests();
      emit(AdminTrialRequestsLoaded(requests));
    } catch (e) {
      emit(AdminTrialRequestsError(e.toString()));
    }
  }

  Future<void> updateStatus(String id, String status) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      await repository.updateStatus(id, status);
      await loadRequests();
    } catch (e) {
      emit(AdminTrialRequestsError(e.toString()));
    }
  }

  Future<void> updateNotes(String id, String notes) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      await repository.updateInternalNotes(id, notes);
      await loadRequests();
    } catch (e) {
      emit(AdminTrialRequestsError(e.toString()));
    }
  }
}
