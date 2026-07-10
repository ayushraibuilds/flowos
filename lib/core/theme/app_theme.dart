import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// FlowOS Dark Theme — the primary theme.
/// "Dark, calm, and alive — moody dark interface with emerald accents,
///  glassmorphic depth, and subtle motion."
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Scaffold
      scaffoldBackgroundColor: AppColors.background0,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.emerald,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.focusBlue,
        onSecondary: AppColors.textInverse,
        error: AppColors.dangerCoral,
        onError: AppColors.textPrimary,
        surface: AppColors.background1,
        onSurface: AppColors.textPrimary,
      ),

      // Text theme
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48, fontWeight: FontWeight.w800, height: 1.0,
            color: AppColors.textPrimary, letterSpacing: -1.0,
          ),
          headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, height: 1.2,
            color: AppColors.textPrimary, letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, height: 1.3,
            color: AppColors.textPrimary, letterSpacing: -0.3,
          ),
          headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w400, height: 1.5,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
            color: AppColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, height: 1.4,
            color: AppColors.textSecondary, letterSpacing: 0.3,
          ),
          labelLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, height: 1.0,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, height: 1.3,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background1,
        selectedItemColor: AppColors.emerald,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.background2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons (primary CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          elevation: 0,
          side: BorderSide(color: AppColors.emerald, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emerald,
          textStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          borderSide: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          borderSide: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          borderSide: BorderSide(color: AppColors.emerald, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.background2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusSheet),
          ),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
        space: 0,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.background3,
        contentTextStyle: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Splash / highlight
      splashColor: AppColors.emerald.withValues(alpha: 0.08),
      highlightColor: AppColors.emerald.withValues(alpha: 0.04),
    );
  }
}
