import 'package:flutter/material.dart';

class AppTheme {
  static const Color blushPink = Color(0xFFE8A8B4);
  static const Color babyPink = Color(0xFFFADCE4);
  static const Color offWhite = Color(0xFFFFF8F9);
  static const Color deepRose = Color(0xFFC45D75);

  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: offWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blushPink,
      brightness: Brightness.light,
      primary: deepRose,
      secondary: babyPink,
      surface: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: offWhite,
      foregroundColor: Colors.black,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(color: Colors.white),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepRose,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF171316),
    colorScheme: ColorScheme.fromSeed(
      seedColor: blushPink,
      brightness: Brightness.dark,
      primary: const Color(0xFFF0A7B8),
      secondary: const Color(0xFF754653),
      surface: const Color(0xFF241E22),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF171316),
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(color: Color(0xFF241E22)),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF30282D),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC45D75),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF241E22),
      selectedItemColor: Color(0xFFF0A7B8),
      unselectedItemColor: Colors.white60,
    ),
  );
}
