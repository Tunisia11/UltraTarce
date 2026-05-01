import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';

class GuidedFocusStep {
  const GuidedFocusStep({
    required this.title,
    required this.message,
    required this.progressLabel,
    required this.primaryLabel,
    required this.targetKey,
    this.isDone = false,
  });

  final String title;
  final String message;
  final String progressLabel;
  final String primaryLabel;
  final GlobalKey? targetKey;
  final bool isDone;
}

class GuidedFocusOverlay extends StatefulWidget {
  const GuidedFocusOverlay({
    super.key,
    required this.visible,
    required this.steps,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
    required this.onPrimaryAction,
  });

  final bool visible;
  final List<GuidedFocusStep> steps;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;
  final VoidCallback onPrimaryAction;

  @override
  State<GuidedFocusOverlay> createState() => _GuidedFocusOverlayState();
}

class _GuidedFocusOverlayState extends State<GuidedFocusOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _scheduleTargetUpdate();
  }

  @override
  void didUpdateWidget(covariant GuidedFocusOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible ||
        widget.currentIndex != oldWidget.currentIndex ||
        widget.steps != oldWidget.steps) {
      _scheduleTargetUpdate();
    }
  }

  void _scheduleTargetUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.visible || widget.steps.isEmpty) return;
      final key = widget.steps[widget.currentIndex].targetKey;
      final context = key?.currentContext;
      final box = context?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) {
        if (_targetRect != null) setState(() => _targetRect = null);
        return;
      }
      final offset = box.localToGlobal(Offset.zero);
      final nextRect = offset & box.size;
      if (_targetRect != nextRect) {
        setState(() => _targetRect = nextRect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.steps.isEmpty) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[widget.currentIndex];
    final isLast = widget.currentIndex == widget.steps.length - 1;
    final progress = (widget.currentIndex + 1) / widget.steps.length;

    return Positioned.fill(
      child: Stack(
        children: [
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 180),
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _FocusScrimPainter(targetRect: _targetRect),
                ),
              ),
            ),
          ),
          if (_targetRect != null)
            Positioned.fromRect(
              rect: _targetRect!.inflate(8),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emerald, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: .28),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _GuidePanel(
            step: step,
            progress: progress,
            isFirst: widget.currentIndex == 0,
            isLast: isLast,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            onSkip: widget.onSkip,
            onPrimaryAction: widget.onPrimaryAction,
          ),
        ],
      ),
    );
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel({
    required this.step,
    required this.progress,
    required this.isFirst,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
    required this.onSkip,
    required this.onPrimaryAction,
  });

  final GuidedFocusStep step;
  final double progress;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 640;
    return SafeArea(
      child: Align(
        alignment: compact ? Alignment.bottomCenter : Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? screenWidth : 520),
            child: Material(
              elevation: 20,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: .28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .16),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            AppAssets.welcomeMascot,
                            width: compact ? 54 : 70,
                            height: compact ? 54 : 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: compact ? 10 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.progressLabel,
                                style: const TextStyle(
                                  color: AppColors.emeraldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.message,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        color: AppColors.emerald,
                        backgroundColor: AppColors.border.withValues(
                          alpha: .45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: compact
                          ? WrapAlignment.start
                          : WrapAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onSkip,
                          child: const Text('Passer'),
                        ),
                        OutlinedButton(
                          onPressed: isFirst ? null : onPrevious,
                          child: const Text('Précédent'),
                        ),
                        OutlinedButton(
                          onPressed: isLast ? null : onNext,
                          child: const Text('Suivant'),
                        ),
                        ElevatedButton.icon(
                          onPressed: onPrimaryAction,
                          icon: Icon(
                            step.isDone
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(step.primaryLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusScrimPainter extends CustomPainter {
  const _FocusScrimPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: .52),
    );
    final rect = targetRect?.inflate(10);
    if (rect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FocusScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
