/// responsive_layout.dart
///
/// Provides a [ResponsiveLayout] widget that automatically applies horizontal padding
/// to its child based on the current screen width. This helps ensure consistent and
/// visually appealing layouts across mobile, tablet, and desktop devices.
///
/// # Usage Example
/// ```dart
/// ResponsiveLayout(
///   child: MyContentWidget(),
/// )
/// ```
///
/// The breakpoints are:
/// - < 600px: mobile (16px padding)
/// - 600–1023px: tablet (32px padding)
/// - >= 1024px: desktop (64px padding)
///
/// # See Also
/// - [MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html) - useful for good UI and adaptability :O

import 'package:flutter/material.dart';

/// A widget that adds responsive horizontal padding to its [child]
/// based on the screen width.
///
/// This is useful for making layouts look good on mobile, tablet, and desktop
/// without manually adjusting padding everywhere.
class ResponsiveLayout extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// Creates a [ResponsiveLayout] that wraps [child] with horizontal padding
  /// according to the current screen width.
  const ResponsiveLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double horizontalPadding;
    if (width < 600) {
      horizontalPadding = 16;
    } else if (width < 1024) {
      horizontalPadding = 32;
    } else {
      horizontalPadding = 64;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
  }
}

// ---
// Points of improvement:
// 1. Consider making the breakpoints and padding values configurable via constructor parameters for more flexibility.
// 2. You could add vertical padding as an option if needed for your layouts.
// 3. For more complex layouts, consider using a layout builder or a package like responsive_builder.
