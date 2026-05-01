import 'dart:async';

import 'package:flutter/material.dart';

import '../inventory/inventory_home_page.dart';
import 'models/store_setup_data.dart';
import 'services/onboarding_service.dart';
import 'widgets/onboarding_screen.dart';
import 'widgets/splash_screen.dart';

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({
    super.key,
    this.splashDuration = _defaultSplashDuration,
    this.holdOnSplash = false,
    this.holdOnOnboarding = false,
    this.showOnboardingEveryLaunch = false,
  });

  static const _defaultSplashDuration = Duration(seconds: 3);

  final Duration splashDuration;
  final bool holdOnSplash;
  final bool holdOnOnboarding;
  final bool showOnboardingEveryLaunch;

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  static const _onboardingService = OnboardingService();

  _LaunchPhase _phase = _LaunchPhase.splash;
  StoreSetupData _setupData = StoreSetupData.empty();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.splashDuration, _finishSplash);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishSplash() {
    if (!mounted) return;
    if (widget.holdOnSplash) return;
    if (widget.holdOnOnboarding) {
      setState(() => _phase = _LaunchPhase.onboarding);
      return;
    }
    final launchState = _onboardingService.loadLaunchState(
      showOnboardingEveryLaunch: widget.showOnboardingEveryLaunch,
    );
    setState(() {
      _setupData = launchState.initialSetup;
      _phase = launchState.shouldShowOnboarding
          ? _LaunchPhase.onboarding
          : _LaunchPhase.home;
    });
  }

  void _completeOnboarding(StoreSetupData setup) {
    if (widget.holdOnOnboarding) return;
    _onboardingService.completeSetup(setup);
    setState(() => _phase = _LaunchPhase.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_phase) {
        _LaunchPhase.splash => const SplashScreen(key: ValueKey('splash')),
        _LaunchPhase.onboarding => OnboardingScreen(
          key: const ValueKey('onboarding'),
          initialSetupData: _setupData,
          allowSkip: false,
          onSetupChanged: _onboardingService.saveDraft,
          onComplete: _completeOnboarding,
        ),
        _LaunchPhase.home => const InventoryHomePage(key: ValueKey('home')),
      },
    );
  }
}

enum _LaunchPhase { splash, onboarding, home }
