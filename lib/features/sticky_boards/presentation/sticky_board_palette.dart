import 'package:flutter/material.dart';

abstract final class StickyBoardPalette {
  static const int teal = 0xFF20B8A8;
  static const int blue = 0xFF4C8FF5;
  static const int indigo = 0xFF6F73E8;
  static const int purple = 0xFFA46BE0;
  static const int pink = 0xFFE36F9F;
  static const int orange = 0xFFF18A45;
  static const int yellow = 0xFFE0B83F;
  static const int red = 0xFFE15F5F;

  static const List<int> values = <int>[
    teal,
    blue,
    indigo,
    purple,
    pink,
    orange,
    yellow,
    red,
  ];

  static Color color(int value) => Color(value);
}
