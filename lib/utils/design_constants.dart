import 'package:flutter/material.dart';

/// Design constants following Apple's Human Interface Guidelines
/// Based on Liquid Glass design system
class DesignConstants {
  // MARK: - Spacing & Layout

  /// Standard padding used throughout the app
  static const double standardPadding = 14.0;

  /// Horizontal padding for page surfaces
  static const double pageHorizontalPadding = 24.0;

  /// Vertical padding for page surfaces
  static const double pageVerticalPadding = 24.0;

  /// Leading content inset for text and content alignment
  static const double leadingContentInset = 26.0;

  /// Standard corner radius for cards and containers
  static const double cornerRadius = 15.0;

  /// Safe area padding
  static const double safeAreaPadding = 30.0;

  /// Title top padding
  static const double titleTopPadding = 8.0;

  /// Title bottom padding (negative for tighter spacing)
  static const double titleBottomPadding = -4.0;

  // MARK: - Grid Spacing

  /// Grid spacing between items
  static const double gridSpacing = 14.0;

  /// Minimum grid item size for iPhone
  static const double gridItemMinSize = 160.0;

  /// Minimum grid item size for iPad/Tablet
  static const double gridItemMinSizeTablet = 240.0;

  /// Maximum grid item size
  static const double gridItemMaxSize = 320.0;

  /// Grid item corner radius
  static const double gridItemCornerRadius = 8.0;

  // MARK: - Typography Spacing

  /// Spacing between headline and body text
  static const double headlineBodySpacing = 16.0;

  /// Spacing between body paragraphs
  static const double bodyParagraphSpacing = 12.0;

  /// Spacing between sections
  static const double sectionSpacing = 24.0;

  // MARK: - Glass Effect Constants

  /// Standard blur sigma for glass effects
  static const double glassBlurSigma = 20.0;

  /// Light glass opacity
  static const double glassOpacityLight = 0.15;

  /// Medium glass opacity
  static const double glassOpacityMedium = 0.25;

  /// Heavy glass opacity
  static const double glassOpacityHeavy = 0.4;

  /// Glass border opacity
  static const double glassBorderOpacity = 0.3;

  /// Glass border width
  static const double glassBorderWidth = 1.5;

  // MARK: - Button Constants

  /// Standard button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 14.0,
  );

  /// Prominent button padding
  static const EdgeInsets prominentButtonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );

  /// Button corner radius
  static const double buttonCornerRadius = 12.0;

  // MARK: - Card Constants

  /// Card corner radius
  static const double cardCornerRadius = 24.0;

  /// Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);

  /// Card elevation (for non-glass cards)
  static const double cardElevation = 2.0;

  // MARK: - Navigation Constants

  /// Bottom navigation height
  static const double bottomNavHeight = 65.0;

  /// Bottom navigation corner radius
  static const double bottomNavCornerRadius = 24.0;

  /// Bottom navigation padding from edges
  static const EdgeInsets bottomNavPadding = EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    bottom: 20.0,
    top: 8.0,
  );

  // MARK: - Animation Durations

  /// Standard animation duration
  static const Duration standardAnimationDuration = Duration(milliseconds: 300);

  /// Fast animation duration
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);

  /// Slow animation duration
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // MARK: - Responsive Breakpoints

  /// Tablet breakpoint width
  static const double tabletBreakpoint = 768.0;

  /// Desktop breakpoint width
  static const double desktopBreakpoint = 1024.0;

  // MARK: - Helper Methods

  /// Get minimum grid item size based on screen width
  static double getGridItemMinSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletBreakpoint) {
      return gridItemMinSizeTablet;
    }
    return gridItemMinSize;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}
