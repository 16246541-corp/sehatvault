import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';

/// Liquid Glass card following Apple's design principles
/// Features gradient header, frosted glass effect, and premium aesthetics
class LiquidGlassCard extends StatefulWidget {
  final Widget header;
  final Widget content;
  final List<Widget>? tags;
  final Color? gradientStart;
  final Color? gradientEnd;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool expandContent;
  final bool enableEntranceAnimation;
  final Duration? animationDuration;
  final double entranceSlideOffset;
  final Curve animationCurve;

  const LiquidGlassCard({
    super.key,
    required this.header,
    required this.content,
    this.tags,
    this.gradientStart,
    this.gradientEnd,
    this.borderRadius = DesignConstants.cardCornerRadius,
    this.padding,
    this.expandContent = false,
    this.enableEntranceAnimation = true,
    this.animationDuration,
    this.entranceSlideOffset = 0.08,
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _configureAnimations();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final animationChanged =
        widget.enableEntranceAnimation != oldWidget.enableEntranceAnimation ||
            widget.animationDuration != oldWidget.animationDuration ||
            widget.animationCurve != oldWidget.animationCurve ||
            widget.entranceSlideOffset != oldWidget.entranceSlideOffset;

    if (animationChanged) {
      _configureAnimations();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _configureAnimations() {
    _controller?.dispose();

    if (widget.enableEntranceAnimation) {
      final duration =
          widget.animationDuration ?? const Duration(milliseconds: 280);
      _controller = AnimationController(
        vsync: this,
        duration: duration,
      );
      final curvedAnimation =
          CurvedAnimation(parent: _controller!, curve: widget.animationCurve);
      _fadeAnimation = curvedAnimation;
      _slideAnimation = Tween<Offset>(
        begin: Offset(0, widget.entranceSlideOffset),
        end: Offset.zero,
      ).animate(curvedAnimation);
      _controller!.forward(from: 0);
    } else {
      _controller = null;
      _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);
      _slideAnimation = const AlwaysStoppedAnimation<Offset>(Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final startColor =
        widget.gradientStart ?? const Color(0xFF8B5CF6); // Purple
    final endColor = widget.gradientEnd ?? const Color(0xFF14B8A6); // Teal

    final effectivePadding = widget.padding ?? DesignConstants.cardPadding;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DesignConstants.glassBlurSigma,
          sigmaY: DesignConstants.glassBlurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: DesignConstants.glassBorderOpacity),
              width: DesignConstants.glassBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [startColor, endColor],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.borderRadius),
                    topRight: Radius.circular(widget.borderRadius),
                  ),
                ),
                child: Container(
                  padding: effectivePadding,
                  child: widget.header,
                ),
              ),
              if (widget.expandContent)
                Expanded(
                    child: _buildContentArea(
                        isDark, effectivePadding, widget.borderRadius))
              else
                _buildContentArea(
                    isDark, effectivePadding, widget.borderRadius),
            ],
          ),
        ),
      ),
    );

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: card,
      ),
    );
  }

  Widget _buildContentArea(
    bool isDark,
    EdgeInsetsGeometry effectivePadding,
    double borderRadius,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool heightBounded =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.expandContent && heightBounded
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            widget.content,
            if (widget.tags != null && widget.tags!.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.headlineBodySpacing),
              Wrap(
                spacing: DesignConstants.standardPadding,
                runSpacing: DesignConstants.standardPadding,
                children: widget.tags!,
              ),
            ],
          ],
        );

        Widget child = column;

        if (widget.expandContent && heightBounded) {
          child = ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
            child: column,
          );
        } else if (widget.expandContent) {
          child = ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: column,
          );
        }

        Widget contentContainer = Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black
                    .withValues(alpha: DesignConstants.glassOpacityHeavy)
                : Colors.black
                    .withValues(alpha: DesignConstants.glassOpacityMedium),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
            ),
          ),
          padding: effectivePadding,
          child: child,
        );

        if (!widget.expandContent) {
          contentContainer = SingleChildScrollView(
            child: contentContainer,
          );
        }

        return contentContainer;
      },
    );
  }
}
