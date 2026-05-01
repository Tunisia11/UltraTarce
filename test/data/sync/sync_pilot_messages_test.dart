import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/remote/remote_errors.dart';
import 'package:ultra_trace/data/sync/sync_pilot_messages.dart';

void main() {
  test('pilot labels describe local-first cloud push clearly', () {
    expect(SyncPilotMessages.modeLabel, 'Mode pilote cloud');
    expect(
      SyncPilotMessages.localThenCloud,
      'Les données sont enregistrées localement puis synchronisées vers le cloud.',
    );
    expect(
      SyncPilotMessages.oneDevicePilot,
      contains('utilisez un poste principal'),
    );
    expect(
      SyncPilotMessages.backupReminder,
      'Téléchargez une sauvegarde à la fin de chaque journée.',
    );
  });

  test(
    'manual sync messages cover local mode, missing config, auth and errors',
    () {
      expect(
        SyncPilotMessages.unavailableMessage(
          authBypassEnabled: true,
          devBypassTenantActive: true,
          hasSupabaseConfig: false,
        ),
        'Mode local: synchronisation cloud désactivée.',
      );
      expect(
        SyncPilotMessages.unavailableMessage(
          authBypassEnabled: false,
          devBypassTenantActive: false,
          hasSupabaseConfig: false,
        ),
        'Connexion cloud non configurée.',
      );
      expect(
        SyncPilotMessages.errorMessage(RemoteErrorCodes.authMissing),
        'Connectez-vous pour synchroniser.',
      );
      expect(
        SyncPilotMessages.errorMessage(RemoteErrorCodes.rlsDenied),
        'Synchronisation échouée. Les données locales sont conservées.',
      );
    },
  );

  test('manual sync success messages avoid overpromising', () {
    expect(
      SyncPilotMessages.successMessage(synced: 0),
      'Aucune modification à synchroniser.',
    );
    expect(
      SyncPilotMessages.successMessage(synced: 3),
      'Synchronisation terminée.',
    );
  });
}
