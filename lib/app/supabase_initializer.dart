import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static Future<void> initialize(AppConfig config) async {
    if (!config.hasSupabaseConfig) return;
    try {
      if (Supabase.instance.isInitialized) return;
    } catch (_) {}
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      debug: false,
    );
  }
}
