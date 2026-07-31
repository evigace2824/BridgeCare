import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized BridgeCare palette + theme. Matches the mockups: a vivid royal
/// blue brand accent against a near-white app background, generous spacing,
/// and Inter typography.
class AppColors {
  // Brand
  static const Color primary = Color(0xFF3B5BDB);
  static const Color primaryDark = Color(0xFF2A46B0);
  static const Color primarySoft = Color(0xFFEEF2FF);

  // Surfaces
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF868E96);
  static const Color textMuted = Color(0xFF868E96);

  // Lines & fills
  static const Color border = Color(0xFFE4E7EC);
  static const Color fieldFill = Colors.white;

  // Semantic — used throughout the patient dashboard so meaning is obvious
  // even with reduced literacy / vision.
  static const Color emergency = Color(0xFFD63031); // SOS, Emergency status
  static const Color emergencySoft = Color(0xFFFFE8E8);
  static const Color success = Color(0xFF2F9E44); // Done, Normal vitals
  static const Color successSoft = Color(0xFFEBFBEE);
  static const Color warning = Color(0xFFF08C00); // Snooze, Warning status
  static const Color warningSoft = Color(0xFFFFF1DE);

  // Patient-facing accent palette for quick action tiles
  static const Color accentTeal = Color(0xFF0891B2);
  static const Color accentTealSoft = Color(0xFFCFFAFE);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPurpleSoft = Color(0xFFEDE9FE);
  static const Color accentPink = Color(0xFFE11D48);
  static const Color accentPinkSoft = Color(0xFFFCE7F3);
}

/// Type scale tuned for elderly / accessibility-first mode.
/// All sizes one notch larger than the auth screens.
class PatientText {
  PatientText._();

  static const double bodyM = 16;
  static const double bodyL = 19;
  static const double titleS = 20;
  static const double titleM = 24;
  static const double titleL = 32;
  static const double display = 36;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD92D20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
