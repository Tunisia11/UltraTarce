import 'package:flutter/widgets.dart';

import 'app_config.dart';
import 'supabase_initializer.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<AppConfig> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    final config = AppConfig.fromEnvironment();
    await SupabaseInitializer.initialize(config);
    return config;
  }
}
