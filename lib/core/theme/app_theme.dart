import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_mobile/Configuration/configuration.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Warna.primary,
      primary: Warna.primary,
      secondary: Warna.success,
      error: Warna.destructive,
      surface: Warna.neutral,
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
      color: Warna.neutral,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Warna.line),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Warna.primary,
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
      seedColor: Warna.primary,
      brightness: Brightness.dark,
      primary: Warna.primary,
      secondary: Warna.success,
      error: Warna.destructive,
      surface: Warna.darkSurface,
      onPrimary: Colors.black,
    ),
    scaffoldBackgroundColor: Warna.darkBG,
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
      color: Warna.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Warna.darkLine),
      ),
    ),
  );
}
