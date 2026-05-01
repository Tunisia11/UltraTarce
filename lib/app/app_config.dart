class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.authBypassEnabled,
    required this.cloudPilotEnabled,
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
    );
  }

  factory AppConfig.devBypass() {
    return const AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      authBypassEnabled: true,
      cloudPilotEnabled: false,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool authBypassEnabled;
  final bool cloudPilotEnabled;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  String? get configurationWarning {
    if (hasSupabaseConfig || authBypassEnabled) return null;
    return 'Configuration Supabase manquante. Lancez avec SUPABASE_URL et SUPABASE_ANON_KEY, ou activez TRACE_AUTH_BYPASS en développement local.';
  }
}
