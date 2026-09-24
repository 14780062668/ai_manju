import 'package:flutter/material.dart';

ThemeData buildManjuTheme() {
  const gold = Color(0xFFE8C17A);
  const background = Color(0xFF0C0C0F);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
    appBarTheme: const AppBarTheme(backgroundColor: background, foregroundColor: Colors.white, elevation: 0),
    cardTheme: const CardThemeData(color: Color(0xFF17171C)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
