import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos_mobile/Configuration/configuration.dart';

/// Single source of truth for every font used in the app.
///
/// Ganti nilai di sini untuk mengubah font di seluruh aplikasi (theme,
/// [ShadThemeData], dan komponen custom yang memakai [AppFonts.body] /
/// [AppFonts.heading] / [AppFonts.mono]).
class AppFonts {
  AppFonts._();

  /// Font untuk judul/heading besar (mis. displayLarge, headlineMedium).
  static TextStyle heading({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  /// Font untuk teks umum (body, tombol, komponen custom).
  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: color);

  /// Font monospace (mis. label kecil, struk).
  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) => GoogleFonts.geistMono(fontSize: fontSize, fontWeight: fontWeight, color: color);

  /// Nama family font body, dipakai untuk [ShadThemeData.textTheme] agar
  /// seluruh komponen shadcn_ui (button, input, dll) ikut memakai font ini.
  static String get bodyFamily => body().fontFamily!;
}

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
      displayLarge: AppFonts.heading(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      headlineMedium: AppFonts.heading(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      bodyLarge: AppFonts.body(fontSize: 16, color: Colors.black87),
      bodyMedium: AppFonts.body(fontSize: 14, color: Colors.black54),
      labelSmall: AppFonts.mono(fontSize: 12, color: Colors.grey),
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
        textStyle: AppFonts.body(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      displayLarge: AppFonts.heading(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: AppFonts.heading(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: AppFonts.body(fontSize: 16, color: Colors.white70),
      bodyMedium: AppFonts.body(fontSize: 14, color: Colors.white60),
      labelSmall: AppFonts.mono(fontSize: 12, color: Colors.grey),
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
