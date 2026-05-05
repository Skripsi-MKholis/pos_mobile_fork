import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFCCFF00);
  static const Color successColor = Color(0xFF10B981);
  static const Color destructiveColor = Color(0xFFE11D48);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFFF8FAFC);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: successColor,
      error: destructiveColor,
      surface: surfaceColor,
      onPrimary: Colors.black,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.black54,
      ),
      labelSmall: GoogleFonts.geistMono(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: successColor,
      error: destructiveColor,
      surface: const Color(0xFF1E1E1E),
      onPrimary: Colors.black,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.white60,
      ),
      labelSmall: GoogleFonts.geistMono(
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
  );
}
