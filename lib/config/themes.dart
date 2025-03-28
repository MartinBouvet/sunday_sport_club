import 'package:flutter/material.dart';

/// Classe qui définit les thèmes de l'application
class AppTheme {
  static const Color _primaryColor = Color(0xFF42A5F5); // Bleu ciel
  static const Color _secondaryColor = Color(0xFF4CAF50); // Vert pour la validation
  static const Color _accentColor = Color(0xFFFF9800); // Orange pour action

  // Constructeur privé pour empêcher l'instanciation
  AppTheme._();

  // Thème clair
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: Colors.grey.shade50,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 3),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryColor,
      linearTrackColor: Colors.grey.shade200,
      circularTrackColor: Colors.grey.shade200,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      selectedColor: _primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(color: Colors.grey.shade800),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // Thème sombre
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1E1E1E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Colors.white, width: 3),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryColor,
      linearTrackColor: Colors.grey.shade800,
      circularTrackColor: Colors.grey.shade800,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2C2C2C),
      selectedColor: _primaryColor.withOpacity(0.3),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: TextStyle(color: Colors.grey.shade800),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}