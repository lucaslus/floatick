import 'package:flutter/material.dart';

import '../../core/ui/floatick_hover_motion.dart';

abstract final class FloatickColors {
  static const teal = Color(0xFF0F8F83);
  static const tealBright = Color(0xFF22B8A7);
  static const orange = Color(0xFFF17842);
  static const ink = Color(0xFF172126);
  static const mutedInk = Color(0xFF657178);
  static const darkSurface = Color(0xFF151B1E);
  static const darkSurfaceElevated = Color(0xFF1D2529);
  static const darkOnSurface = Color(0xFFEEF2F1);
  static const lightSurface = Color(0xFFF9FBFA);
}

ThemeData buildFloatickTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: FloatickColors.teal,
        brightness: brightness,
      ).copyWith(
        primary: isDark ? FloatickColors.tealBright : FloatickColors.teal,
        secondary: FloatickColors.orange,
        surface: isDark
            ? FloatickColors.darkSurface
            : FloatickColors.lightSurface,
        onSurface: isDark ? FloatickColors.darkOnSurface : FloatickColors.ink,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    fontFamily: '.AppleSystemUIFont',
    platform: TargetPlatform.macOS,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.standard,
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: FloatickMotion.hoverDuration,
        foregroundBuilder: FloatickMotion.iconButtonForegroundBuilder,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.28);
          }
          if (states.contains(WidgetState.selected) ||
              states.contains(WidgetState.pressed)) {
            return colorScheme.primary;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colorScheme.onSurface.withValues(alpha: 0.92);
          }
          return colorScheme.onSurface.withValues(alpha: 0.62);
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        animationDuration: FloatickMotion.hoverDuration,
        foregroundBuilder: FloatickMotion.buttonForegroundBuilder,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        animationDuration: FloatickMotion.hoverDuration,
        foregroundBuilder: FloatickMotion.buttonForegroundBuilder,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        animationDuration: FloatickMotion.hoverDuration,
        foregroundBuilder: FloatickMotion.buttonForegroundBuilder,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        animationDuration: FloatickMotion.hoverDuration,
        foregroundBuilder: FloatickMotion.buttonForegroundBuilder,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.22),
      selectionHandleColor: colorScheme.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? FloatickColors.darkSurfaceElevated
          : const Color(0xFFF0F4F2),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      hintStyle: TextStyle(
        color: isDark
            ? colorScheme.onSurface.withValues(alpha: 0.58)
            : FloatickColors.mutedInk,
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? colorScheme.onSurface.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.045),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF313B3F) : const Color(0xFF253034),
        borderRadius: BorderRadius.circular(7),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
