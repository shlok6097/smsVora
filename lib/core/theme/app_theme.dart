import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.softCream,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.deepEspresso,
        onPrimary: AppColors.softCream,
        secondary: AppColors.chestnut,
        onSecondary: AppColors.softCream,
        tertiary: AppColors.warmTaupe,
        onTertiary: AppColors.deepEspresso,
        surface: AppColors.softCream,
        onSurface: AppColors.deepEspresso,
        surfaceContainerHighest: AppColors.greigeStone,
        error: Color(0xFFB3261E),
        onError: AppColors.white,
        outline: AppColors.warmTaupe,
        outlineVariant: AppColors.greigeStone,
        surfaceContainerLow: AppColors.extraLight,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.deepEspresso,
        displayColor: AppColors.deepEspresso,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepEspresso,
        foregroundColor: AppColors.softCream,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.softCream,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.softCream,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.greigeStone,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greigeStone,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.warmTaupe,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.chestnut,
            width: 1.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.chestnut,
        foregroundColor: AppColors.softCream,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.deepEspresso,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.greigeStone,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.softCream,
        selectedItemColor: AppColors.deepEspresso,
        unselectedItemColor: AppColors.warmTaupe,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.extraLight,
        selectedColor: AppColors.chestnut,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.deepEspresso,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.softCream,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: AppColors.greigeStone),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.deepEspresso;
          }
          return AppColors.warmTaupe;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.greigeStone;
          }
          return AppColors.extraLight;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.softCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.deepEspresso,
        ),
      ),
    );
  }
}
