import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.success,
        surface: AppColors.card,
        onSurface: AppColors.slate900,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        bodyMedium: GoogleFonts.poppins(color: AppColors.slate700),
        labelSmall: GoogleFonts.poppins(color: AppColors.slate500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.slate900,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate500,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.slate500),
      ),
    );
  }

  // Dark theme
  static ThemeData darkTheme() {
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);
    const darkCard = Color(0xFF252525);
    const darkText = Color(0xFFF3F4F6);
    const darkTextMuted = Color(0xFF9CA3AF);
    const darkDivider = Color(0xFF2E2E2E);

    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.success,
        surface: darkCard,
        onSurface: darkText,
        onBackground: darkText,
      ),
      dividerColor: darkDivider,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: darkText,
        ),
        bodyLarge: GoogleFonts.poppins(color: darkText),
        bodyMedium: GoogleFonts.poppins(color: darkTextMuted),
        labelMedium: GoogleFonts.poppins(color: darkTextMuted),
        labelSmall: GoogleFonts.poppins(color: darkTextMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: darkTextMuted,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: darkSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.poppins(color: darkTextMuted),
        labelStyle: GoogleFonts.poppins(color: darkTextMuted),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: darkTextMuted,
        textColor: darkText,
      ),
    );
  }
}
