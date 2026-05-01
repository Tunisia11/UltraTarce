import 'package:flutter/material.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/tenant_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/onboarding/app_launch_gate.dart';
import 'app_config.dart';
import 'app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.holdOnSplash = false,
    this.holdOnOnboarding = _holdOnboardingForEditing,
    this.showOnboardingEveryLaunch = _showOnboardingEveryLaunchForDebug,
    this.splashDuration = const Duration(seconds: 3),
    this.enableAuth = true,
    this.config,
    this.authRepository,
    this.tenantRepository,
  });

  static const _holdOnboardingForEditing = false;
  static const _showOnboardingEveryLaunchForDebug = false;

  final bool holdOnSplash;
  final bool holdOnOnboarding;
  final bool showOnboardingEveryLaunch;
  final Duration splashDuration;
  final bool enableAuth;
  final AppConfig? config;
  final AuthRepository? authRepository;
  final TenantRepository? tenantRepository;

  @override
  Widget build(BuildContext context) {
    final launchGate = AppLaunchGate(
      splashDuration: splashDuration,
      holdOnSplash: holdOnSplash,
      holdOnOnboarding: holdOnOnboarding,
      showOnboardingEveryLaunch: showOnboardingEveryLaunch,
    );
    return MaterialApp(
      title: 'Trace Ultra',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: enableAuth
          ? AuthGate(
              config: config,
              authRepository: authRepository,
              tenantRepository: tenantRepository,
              inventoryBuilder: (_) => launchGate,
            )
          : launchGate,
    );
  }
}
