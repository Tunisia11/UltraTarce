import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';
import 'app/trace_ultra_app.dart';

export 'app/trace_ultra_app.dart';
export 'core/formatters.dart';
export 'domain/app_enums.dart';
export 'domain/app_models.dart';
export 'features/inventory/inventory_home_page.dart';
export 'storage/app_storage_keys.dart';

Future<void> main() async {
  final config = await AppBootstrap.initialize();
  runApp(MyApp(config: config));
}
