import 'local_tenant_data_status.dart';

/// States for the cloud bootstrap cubit.
abstract class CloudBootstrapState {
  const CloudBootstrapState();
}

class CloudBootstrapInitial extends CloudBootstrapState {
  const CloudBootstrapInitial();
}

class CloudBootstrapChecking extends CloudBootstrapState {
  const CloudBootstrapChecking();
}

/// Local data exists and is ready — skip bootstrap.
class CloudBootstrapLocalReady extends CloudBootstrapState {
  const CloudBootstrapLocalReady();
}

/// Local has data but user might want cloud pull.
class CloudBootstrapNeedsChoice extends CloudBootstrapState {
  const CloudBootstrapNeedsChoice({
    required this.localStatus,
    required this.pendingOutboxCount,
  });

  final LocalTenantDataStatus localStatus;
  final int pendingOutboxCount;
}

/// Pulling cloud data in progress.
class CloudBootstrapPulling extends CloudBootstrapState {
  const CloudBootstrapPulling({this.message = 'Téléchargement…'});

  final String message;
}

/// Cloud pull completed successfully.
class CloudBootstrapSuccess extends CloudBootstrapState {
  const CloudBootstrapSuccess({required this.importedRows});

  final int importedRows;
}

/// Cloud pull failed.
class CloudBootstrapFailure extends CloudBootstrapState {
  const CloudBootstrapFailure({
    required this.message,
    required this.hasLocalData,
  });

  final String message;
  final bool hasLocalData;
}
