import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// Clickable map of the setup steps.
///
/// Steps stay disabled until the previous answers unlock them. Tapping an
/// unlocked step lets you review or edit that part of the setup without leaving
/// onboarding page 2.
class SetupStepMap extends StatelessWidget {
  const SetupStepMap({
    super.key,
    required this.activeStep,
    required this.maxUnlockedStep,
    required this.completedSteps,
    required this.onStepSelected,
  });

  static const _steps = [
    _SetupStepMapItem(1, 'Magasin'),
    _SetupStepMapItem(2, 'Commerce'),
    _SetupStepMapItem(3, 'Dépôt'),
    _SetupStepMapItem(4, 'Prix'),
    _SetupStepMapItem(5, 'Timbre'),
  ];

  final int activeStep;
  final int maxUnlockedStep;
  final Set<int> completedSteps;
  final ValueChanged<int> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        return Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: .14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .06),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PlanBadge(currentStep: activeStep),
                      const SizedBox(width: 8),
                      for (final step in _steps) ...[
                        _StepMapPill(
                          step: step,
                          active: activeStep == step.number,
                          completed: completedSteps.contains(step.number),
                          unlocked: step.number <= maxUnlockedStep,
                          onTap: () => onStepSelected(step.number),
                        ),
                        if (step.number != _steps.last.number)
                          _StepConnector(
                            done: completedSteps.contains(step.number),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.route_outlined,
            color: AppColors.emeraldDark,
            size: 17,
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Plan',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Étape ${currentStep.clamp(1, 5)}',
                style: const TextStyle(
                  color: AppColors.subtle,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 12,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: done
            ? AppColors.emerald.withValues(alpha: .55)
            : AppColors.border.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _StepMapPill extends StatelessWidget {
  const _StepMapPill({
    required this.step,
    required this.active,
    required this.completed,
    required this.unlocked,
    required this.onTap,
  });

  final _SetupStepMapItem step;
  final bool active;
  final bool completed;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? Colors.white
        : completed
        ? AppColors.emeraldDark
        : unlocked
        ? AppColors.ink
        : AppColors.subtle.withValues(alpha: .48);
    final background = active
        ? AppColors.emeraldDark
        : completed
        ? AppColors.emerald.withValues(alpha: .1)
        : unlocked
        ? AppColors.surfaceLow.withValues(alpha: .72)
        : AppColors.surfaceContainer.withValues(alpha: .5);
    final borderColor = active
        ? AppColors.emeraldDark
        : completed
        ? AppColors.emerald.withValues(alpha: .22)
        : unlocked
        ? AppColors.border.withValues(alpha: .22)
        : Colors.transparent;

    return Semantics(
      button: true,
      enabled: unlocked,
      label: 'Étape ${step.number}, ${step.label}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 112,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.emeraldDark.withValues(alpha: .18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: .16)
                        : completed
                        ? Colors.white
                        : Colors.white.withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: completed && !active
                      ? Icon(Icons.check_rounded, size: 16, color: foreground)
                      : Text(
                          step.number.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStepMapItem {
  const _SetupStepMapItem(this.number, this.label);

  final int number;
  final String label;
}
