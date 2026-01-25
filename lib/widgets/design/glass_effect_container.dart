import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';

/// Glass Effect Container following Apple's Liquid Glass design
class GlassEffectContainer extends StatelessWidget {
  final Widget child;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const GlassEffectContainer({
    super.key,
    required this.child,
    this.spacing = DesignConstants.standardPadding,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: child,
    );
  }
}

/// Glass effect modifier for individual views
class GlassEffect extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final bool interactive;

  const GlassEffect({
    super.key,
    required this.child,
    this.blurSigma = DesignConstants.glassBlurSigma,
    this.opacity = DesignConstants.glassOpacityLight,
    this.tintColor,
    this.borderRadius,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOpacity = isDark ? opacity * 1.2 : opacity;
    final effectiveTintColor = tintColor ?? Colors.white;

    return ClipRRect(
      borderRadius:
          borderRadius ?? BorderRadius.circular(DesignConstants.cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: effectiveTintColor.withValues(alpha: effectiveOpacity),
            borderRadius: borderRadius ??
                BorderRadius.circular(DesignConstants.cornerRadius),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: DesignConstants.glassBorderOpacity),
              width: DesignConstants.glassBorderWidth,
            ),
          ),
          child: interactive
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: borderRadius ??
                        BorderRadius.circular(DesignConstants.cornerRadius),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

/// Glass effect with rounded rectangle shape
class GlassEffectRounded extends GlassEffect {
  GlassEffectRounded({
    super.key,
    required super.child,
    super.blurSigma,
    super.opacity,
    super.tintColor,
    double? cornerRadius,
    super.interactive,
  }) : super(
          borderRadius: BorderRadius.circular(cornerRadius ?? 15.0),
        );
}

/// Glass effect with capsule shape (for buttons)
class GlassEffectCapsule extends GlassEffect {
  GlassEffectCapsule({
    super.key,
    required super.child,
    super.blurSigma,
    super.opacity,
    super.tintColor,
    super.interactive,
  }) : super(
          borderRadius: BorderRadius.circular(100),
        );
}
