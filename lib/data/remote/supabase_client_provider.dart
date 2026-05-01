import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_config.dart';
import '../../core/result/app_result.dart';
import 'remote_errors.dart';

class SupabaseClientProvider {
  const SupabaseClientProvider({required this.config, this.clientOverride});

  final AppConfig config;
  final SupabaseClient? clientOverride;

  bool get isConfigured => config.hasSupabaseConfig || clientOverride != null;

  SupabaseClient? get clientOrNull {
    final override = clientOverride;
    if (override != null) return override;
    if (!config.hasSupabaseConfig) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AppResult<SupabaseClient> requireClient() {
    final client = clientOrNull;
    if (client != null) return AppSuccess(client);
    return const AppFailure(
      AppError(
        code: RemoteErrorCodes.missingSupabaseConfig,
        message:
            'Supabase n’est pas configuré. La synchronisation distante est inactive.',
      ),
    );
  }
}
