import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === Colors ===
  static const Color primaryColor = Color(0xFF000000); // Đen tuyền thanh lịch
  static const Color secondaryColor = Color(0xFFD4B39A); // Be nhạt / Nude
  static const Color accentColor = Color(0xFF4A4A4A); // Xám đậm
  static const Color backgroundColor = Color(0xFFFFFFFF); // Trắng
  static const Color surfaceColor = Color(0xFFF9F9F9); // Xám cực nhạt mịn
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFFBC02D);
  static const Color textPrimary = Color(0xFF111111); // Đen mun (để chữ dễ đọc hơn)
  static const Color textSecondary = Color(0xFF888888); // Xám vừa
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color dividerColor = Color(0xFFEFEFEF);
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // === Light Theme ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
      error: errorColor,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      displayMedium: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      displaySmall: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      headlineLarge: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      headlineSmall: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.5),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textPrimary),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, color: textPrimary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero), // Nút góc vuông thời trang
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: errorColor),
      ),
      hintStyle: const TextStyle(color: textHint),
    ),
    cardTheme: CardThemeData(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: dividerColor, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      selectedColor: primaryColor,
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      labelStyle: const TextStyle(fontSize: 13, color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  // === Dark Theme ===
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFFFFFF),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFFFFFF),
      secondary: secondaryColor,
      surface: const Color(0xFF1E1E1E),
      error: errorColor,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
      displayMedium: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
      displaySmall: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
      headlineLarge: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
      headlineMedium: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
      headlineSmall: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600, color: Colors.white),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Color(0xFF2C2C2C), width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xFF757575),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
