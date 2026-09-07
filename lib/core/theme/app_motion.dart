import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);

  static const Duration normal = Duration(milliseconds: 250);

  static const Duration slow = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;

  static const Curve move = Curves.easeInOutCubic;
}
