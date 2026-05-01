import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class BlinkingContinueButton extends StatefulWidget {
  const BlinkingContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<BlinkingContinueButton> createState() => _BlinkingContinueButtonState();
}

class _BlinkingContinueButtonState extends State<BlinkingContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: .78, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _scale = Tween<double>(begin: .985, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _glow = Tween<double>(begin: .12, end: .38).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldDark.withValues(alpha: _glow.value),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        child: Text(widget.label),
      ),
    );
  }
}
