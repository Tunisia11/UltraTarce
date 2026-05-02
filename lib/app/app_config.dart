import '../domain/app_enums.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.authBypassEnabled,
    required this.cloudPilotEnabled,
    required this.signupMode,
  });

  factory AppConfig.fromEnvironment({bool? authBypassOverride}) {
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return AppConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: anonKey.isNotEmpty ? anonKey : publishableKey,
      authBypassEnabled:
          authBypassOverride ?? const bool.fromEnvironment('TRACE_AUTH_BYPASS'),
      cloudPilotEnabled: const bool.fromEnvironment('TRACE_CLOUD_PILOT'),
      signupMode: _parseSignupMode(
        const String.fromEnvironment(
          'TRACE_SIGNUP_MODE',
          defaultValue: 'trial_request',
        ),
      ),
    );
  }

  static SignupMode _parseSignupMode(String value) {
    return switch (value.toLowerCase()) {
      'public' => SignupMode.public,
      'invite_only' => SignupMode.inviteOnly,
      _ => SignupMode.trialRequest,
    };
  }

  factory AppConfig.devBypass() {
    return const AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      authBypassEnabled: true,
      cloudPilotEnabled: false,
      signupMode: SignupMode.public,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool authBypassEnabled;
  final bool cloudPilotEnabled;
  final SignupMode signupMode;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  String? get configurationWarning {
    if (hasSupabaseConfig || authBypassEnabled) return null;
    return 'Configuration Supabase manquante. Lancez avec SUPABASE_URL et SUPABASE_ANON_KEY, ou activez TRACE_AUTH_BYPASS en développement local.';
  }
}
