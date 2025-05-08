// responsive_layout.dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

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
