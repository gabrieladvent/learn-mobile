import 'package:flutter/material.dart';

abstract final class AppGradients {
  static const List<Color> brand = [Color(0xFF6366F1), Color(0xFF8B5CF6)];

  static const List<Color> calm = [Color(0xFF38BDF8), Color(0xFF2DD4BF)];

  static const List<Color> warm = [Color(0xFFFBBF24), Color(0xFFF472B6)];
}

abstract final class AppSemantic {
  static const _successLight = Color(0xFF15803D);
  static const _successDark = Color(0xFF4ADE80);

  static const _infoLight = Color(0xFF1D4ED8);
  static const _infoDark = Color(0xFF7DA2FF);

  static const _warningLight = Color(0xFFB45309);
  static const _warningDark = Color(0xFFFBBF24);

  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? _successDark : _successLight;

  static Color info(Brightness brightness) =>
      brightness == Brightness.dark ? _infoDark : _infoLight;

  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? _warningDark : _warningLight;
}
