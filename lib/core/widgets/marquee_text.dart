import 'dart:async';
import 'package:flutter/material.dart';

/// A widget that displays text and automatically scrolls horizontally (marquee effect)
/// only when the text content exceeds the available width.
/// If the text fits completely, it renders as standard static text with zero overhead.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration pauseDuration;
  final Duration backPauseDuration;
  final double pixelsPerSecond;
  final TextAlign textAlign;
  final TextDirection? textDirection;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.pauseDuration = const Duration(milliseconds: 1800),
    this.backPauseDuration = const Duration(milliseconds: 1400),
    this.pixelsPerSecond = 32.0,
    this.textAlign = TextAlign.start,
    this.textDirection,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;
  Timer? _stepTimer;
  bool _isLoopRunning = false;
  int _loopSessionId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _resetLoop();
    }
  }

  void _resetLoop() {
    _loopSessionId++;
    _stepTimer?.cancel();
    _stepTimer = null;
    _isLoopRunning = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _scheduleStep(int sessionId, VoidCallback action, Duration delay) {
    _stepTimer?.cancel();
    _stepTimer = Timer(delay, () {
      if (!mounted || !_isLoopRunning || _loopSessionId != sessionId) return;
      action();
    });
  }

  void _startLoopIfNeeded(double overflow) {
    if (overflow <= 0.5) {
      _resetLoop();
      return;
    }
    if (_isLoopRunning) return;

    _isLoopRunning = true;
    final currentSession = ++_loopSessionId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isLoopRunning && _loopSessionId == currentSession) {
        _scheduleStep(currentSession, () => _startForward(currentSession), widget.pauseDuration);
      }
    });
  }

  void _startForward(int sessionId) {
    if (!mounted || !_isLoopRunning || _loopSessionId != sessionId) return;
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0.5) return;

    final forwardDuration = Duration(
      milliseconds: ((maxExtent / widget.pixelsPerSecond) * 1000).toInt().clamp(600, 15000),
    );

    _scrollController
        .animateTo(
          maxExtent,
          duration: forwardDuration,
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (!mounted || !_isLoopRunning || _loopSessionId != sessionId) return;
          _scheduleStep(sessionId, () => _startReverse(sessionId), widget.backPauseDuration);
        })
        .catchError((_) {});
  }

  void _startReverse(int sessionId) {
    if (!mounted || !_isLoopRunning || _loopSessionId != sessionId) return;
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final reverseDuration = Duration(
      milliseconds: ((maxExtent / widget.pixelsPerSecond) * 1000).toInt().clamp(600, 15000),
    );

    _scrollController
        .animateTo(
          0,
          duration: reverseDuration,
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          if (!mounted || !_isLoopRunning || _loopSessionId != sessionId) return;
          _scheduleStep(sessionId, () => _startForward(sessionId), widget.pauseDuration);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _resetLoop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final direction = widget.textDirection ?? Directionality.of(context);
        final defaultStyle = DefaultTextStyle.of(context).style;
        final effectiveStyle = defaultStyle.merge(widget.style);

        // Measure true text width without wrapping
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textDirection: direction,
          maxLines: 1,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        final textWidth = textPainter.width;
        final overflow = textWidth - availableWidth;

        // If constraints are unconstrained or text fits completely, render standard Text
        if (!availableWidth.isFinite || overflow <= 0.5) {
          if (_isLoopRunning) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _resetLoop();
            });
          }
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.clip,
          );
        }

        // Text exceeds available width: trigger scrolling marquee
        _startLoopIfNeeded(overflow);

        return RepaintBoundary(
          child: ClipRect(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
