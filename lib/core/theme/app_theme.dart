import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryColor = Color(0xFF6C63FF);
  static const Color _secondaryColor = Color(0xFF03DAC6);
  static const Color _errorColor = Color(0xFFCF6679);

  // Status colors
  static const Color completedColor = Color(0xFF4CAF50);
  static const Color plannedColor = Color(0xFF6C63FF);
  static const Color missedColor = Color(0xFFFF5722);
  static const Color adhocColor = Color(0xFF03DAC6);

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
      surface: Color(0xFF1E1E2E),
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF13131F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF13131F),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2E2E3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E3E),
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E2E),
      ),
    );
  }

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      error: _errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
