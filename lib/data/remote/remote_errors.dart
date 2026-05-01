class RemoteErrorCodes {
  const RemoteErrorCodes._();

  static const missingSupabaseConfig = 'missing_supabase_config';
  static const missingTenantId = 'missing_tenant_id';
  static const authMissing = 'auth_missing';
  static const rlsDenied = 'rls_denied';
  static const networkError = 'network_error';
  static const dependencyMissing = 'dependency_missing';
  static const validationError = 'validation_error';
  static const unknownRemoteError = 'unknown_remote_error';
  static const remoteReadFailed = 'remote_read_failed';
  static const remoteWriteFailed = 'remote_write_failed';
  static const remoteSoftDeleteFailed = 'remote_soft_delete_failed';
}

class RemoteRepositoryException implements Exception {
  const RemoteRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
