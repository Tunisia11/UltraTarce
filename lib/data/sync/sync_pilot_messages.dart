import '../remote/remote_errors.dart';

class SyncPilotMessages {
  const SyncPilotMessages._();

  static const modeLabel = 'Mode pilote cloud';
  static const localThenCloud =
      'Les données sont enregistrées localement puis synchronisées vers le cloud.';
  static const oneDevicePilot =
      'Pour cette version pilote, utilisez un poste principal. La synchronisation multi-postes complète arrive après validation.';
  static const backupReminder =
      'Téléchargez une sauvegarde à la fin de chaque journée.';

  static String? unavailableMessage({
    required bool authBypassEnabled,
    required bool devBypassTenantActive,
    required bool hasSupabaseConfig,
  }) {
    if (authBypassEnabled || devBypassTenantActive) {
      return 'Mode local: synchronisation cloud désactivée.';
    }
    if (!hasSupabaseConfig) return 'Connexion cloud non configurée.';
    return null;
  }

  static String errorMessage(String code) {
    return switch (code) {
      RemoteErrorCodes.authMissing => 'Connectez-vous pour synchroniser.',
      RemoteErrorCodes.missingSupabaseConfig =>
        'Connexion cloud non configurée.',
      _ => 'Synchronisation échouée. Les données locales sont conservées.',
    };
  }

  static String successMessage({required int synced}) {
    if (synced <= 0) return 'Aucune modification à synchroniser.';
    return 'Synchronisation terminée.';
  }
}
