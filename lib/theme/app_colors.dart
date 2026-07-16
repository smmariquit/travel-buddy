import 'package:flutter/material.dart';

/// Intentional TravelBuddy brand palette (green travel theme).
abstract final class AppColors {
  static const Color primary = Color(0xFF017E03);
  static const Color accent = Color(0xFF3CC08E);
  static const Color highlight = Color(0xFFFF7029);
  static const Color homeGradientTop = Color(0xFFAED581);
  static const Color authGradientBottom = Color(0xFFE8F5E9);

  static const LinearGradient homeBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [homeGradientTop, Colors.white],
    stops: [0.0, 0.3],
  );

  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, authGradientBottom],
  );
}
