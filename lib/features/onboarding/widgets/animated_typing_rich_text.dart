import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'typing_caret.dart';

class AnimatedTypingRichText extends StatefulWidget {
  const AnimatedTypingRichText({
    super.key,
    required this.segments,
    required this.style,
    required this.caretColor,
    this.duration = const Duration(milliseconds: 4200),
    this.textAlign = TextAlign.left,
    this.autoStart = true,
    this.onFinished,
  });

  final List<TypingTextSegment> segments;
  final TextStyle style;
  final Color caretColor;
  final Duration duration;
  final TextAlign textAlign;
  final bool autoStart;
  final VoidCallback? onFinished;

  @override
  State<AnimatedTypingRichText> createState() => _AnimatedTypingRichTextState();
}

class _AnimatedTypingRichTextState extends State<AnimatedTypingRichText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late _TypingTimeline _timeline;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    _timeline = _TypingTimeline(widget.segments);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleStatus);
    if (widget.autoStart) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedTypingRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments ||
        oldWidget.duration != widget.duration) {
      _timeline = _TypingTimeline(widget.segments);
      _finishedNotified = false;
      _controller
        ..duration = widget.duration
        ..value = 0;
      if (widget.autoStart) _controller.forward();
    } else if (!oldWidget.autoStart && widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _finishedNotified) return;
    _finishedNotified = true;
    final onFinished = widget.onFinished;
    if (onFinished == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _timeline.fullText,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final visibleCharacters = _timeline.visibleCharacters(
              _controller.value,
            );
            final isTyping = visibleCharacters < _timeline.length;
            final caretVisible = _caretVisible(_controller.value, isTyping);

            return Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: _richText(
                    spans: _buildSpans(_timeline.length),
                    includeCaret: false,
                  ),
                ),
                Positioned.fill(
                  child: _richText(
                    spans: _buildSpans(visibleCharacters),
                    includeCaret: true,
                    caretVisible: caretVisible,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _caretVisible(double progress, bool isTyping) {
    if (!isTyping) return true;
    return math.sin(progress * math.pi * 46) > -.18;
  }

  Text _richText({
    required List<InlineSpan> spans,
    required bool includeCaret,
    bool caretVisible = true,
  }) {
    final fontSize = widget.style.fontSize ?? 48;
    return Text.rich(
      TextSpan(
        children: [
          ...spans,
          if (includeCaret)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: TypingCaret(
                color: widget.caretColor,
                height: fontSize * .76,
                visible: caretVisible,
              ),
            ),
        ],
      ),
      textAlign: widget.textAlign,
      style: widget.style,
    );
  }

  List<InlineSpan> _buildSpans(int visibleCharacters) {
    var remaining = visibleCharacters;
    final spans = <InlineSpan>[];

    for (final segment in widget.segments) {
      if (remaining <= 0) break;
      final take = math.min(remaining, segment.text.length);
      spans.add(
        TextSpan(
          text: segment.text.substring(0, take),
          style: TextStyle(color: segment.color),
        ),
      );
      remaining -= take;
    }

    return spans;
  }
}

class TypingTextSegment {
  const TypingTextSegment(this.text, this.color);

  final String text;
  final Color color;
}

class _TypingTimeline {
  _TypingTimeline(this.segments)
    : fullText = segments.map((segment) => segment.text).join() {
    for (var i = 0; i < fullText.length; i++) {
      _weights.add(_weightFor(fullText[i]));
    }
    _totalWeight = _weights.fold<double>(0, (sum, weight) => sum + weight);
  }

  final List<TypingTextSegment> segments;
  final String fullText;
  final List<double> _weights = [];
  late final double _totalWeight;

  int get length => fullText.length;

  int visibleCharacters(double progress) {
    if (progress <= 0) return 0;
    if (progress >= 1) return length;

    final targetWeight = _totalWeight * Curves.easeOutCubic.transform(progress);
    var accumulated = 0.0;

    for (var index = 0; index < _weights.length; index++) {
      accumulated += _weights[index];
      if (accumulated >= targetWeight) return index + 1;
    }

    return length;
  }

  double _weightFor(String character) {
    if (character == '\n') return 3.8;
    if (character == ' ') return .46;
    if (character == ',' || character == '.') return 3.0;
    if (character == 'à') return 1.45;
    return 1;
  }
}
