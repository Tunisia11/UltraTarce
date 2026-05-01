import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../models/store_setup_data.dart';
import 'onboarding_controls.dart';
import 'onboarding_page.dart';
import 'onboarding_top_bar.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.initialSetupData = const StoreSetupData(
      storeName: '',
      taxId: '',
      address: '',
      city: '',
      phone: '',
      email: '',
      commerceType: 'Électronique',
      depotName: '',
      depotCode: '',
      depotCity: '',
      depotAddress: '',
      priceMode: 'Prix TTC',
      timbreFiscal: true,
    ),
    this.onSetupChanged,
    this.allowSkip = false,
  });

  final ValueChanged<StoreSetupData> onComplete;
  final ValueChanged<StoreSetupData>? onSetupChanged;
  final StoreSetupData initialSetupData;
  final bool allowSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _setupComplete = false;
  late StoreSetupData _setupData;

  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _setupData = widget.initialSetupData;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index == _pageCount - 1) {
      _completeOnboarding();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _completeOnboarding() {
    widget.onComplete(_setupData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 40 : 20,
                    18,
                    isWide ? 40 : 20,
                    10,
                  ),
                  child: OnboardingTopBar(
                    allowSkip: widget.allowSkip,
                    onSkip: _completeOnboarding,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pageCount,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        index: index,
                        isActive: index == _index,
                        initialSetupData: _setupData,
                        onSetupCompletionChanged: (complete) {
                          if (_setupComplete == complete) return;
                          setState(() => _setupComplete = complete);
                        },
                        onSetupChanged: (data) {
                          _setupData = data;
                          widget.onSetupChanged?.call(data);
                        },
                        onNext: _goNext,
                      );
                    },
                  ),
                ),
                if (_index > 0)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 40 : 20,
                      8,
                      isWide ? 40 : 20,
                      22,
                    ),
                    child: OnboardingControls(
                      index: _index,
                      total: _pageCount,
                      canGoNext: _index != 1 || _setupComplete,
                      onBack: _goBack,
                      onNext: _goNext,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
