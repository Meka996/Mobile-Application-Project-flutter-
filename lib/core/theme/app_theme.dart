import 'package:flutter/material.dart';

class AppTheme {
  static const Color blushPink = Color(0xFFE8A8B4);
  static const Color babyPink = Color(0xFFFADCE4);
  static const Color offWhite = Color(0xFFFFF8F9);
  static const Color deepRose = Color(0xFFC45D75);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: offWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blushPink,
      primary: deepRose,
      secondary: babyPink,
      surface: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: Colors.black,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepRose,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
