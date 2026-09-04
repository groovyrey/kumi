import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Light theme base values ───────────────────────────────────────
  // Warm monochrome + one muted pastel accent.
  static const _lBackground = Color(0xFFF6F4EF); // warm bone
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lOnSurface = Color(0xFF2A2B2E); // off-black charcoal
  static const _lOnSurfaceVar = Color(0xFF77767C); // muted gray
  static const _lOutline = Color(0xFFE6E4DE); // ultra-light warm gray
  static const _lCardBorder = Color(0xFFE6E4DE);
  static const _lError = Color(0xFF9F2F2D);
  static const _lAccent = Color(0xFF1F6C9F); // muted blue text/icon
  static const _lAccentSoft = Color(0xFFE1F3FE); // pale blue
  static const _lSurfaceVar = Color(0xFFF0EEE9);
  static const _lOnAccent = Color(0xFFFFFFFF);

  // ── Dark theme base values ────────────────────────────────────────
  static const _dBckground = Color(0xFF131214); // warm near-black
  static const _dSurface = Color(0xFF1C1B1F);
  static const _dOnSurface = Color(0xFFEDEBE6);
  static const _dOnSurfaceVar = Color(0xFF9B998F);
  static const _dOutline = Color(0xFF2C2B2F);
  static const _dCardBorder = Color(0xFF2C2B2F);
  static const _dError = Color(0xFFE58B89);
  static const _dAccent = Color(0xFF85C1E9);
  static const _dAccentSoft = Color(0xFF1B2A33);
  static const _dSurfaceVar = Color(0xFF26252A);
  static const _dOnAccent = Color(0xFF00141F);

  // ── Runtime brightness flag ────────────────────────────────────────
  static bool _isDark = false;

  static void setThemeBrightness(Brightness b) =>
      _isDark = b == Brightness.dark;

  // ── Theme-aware getters ────────────────────────────────────────────
  static Color get background => _isDark ? _dBckground : _lBackground;
  static Color get surface => _isDark ? _dSurface : _lSurface;
  static Color get onSurface => _isDark ? _dOnSurface : _lOnSurface;
  static Color get onSurfaceVariant => _isDark ? _dOnSurfaceVar : _lOnSurfaceVar;
  static Color get outline => _isDark ? _dOutline : _lOutline;
  static Color get cardBorder => _isDark ? _dCardBorder : _lCardBorder;
  static Color get error => _isDark ? _dError : _lError;
  static Color get accent => _isDark ? _dAccent : _lAccent;
  static Color get accentSoft => _isDark ? _dAccentSoft : _lAccentSoft;
  static Color get surfaceVariant => _isDark ? _dSurfaceVar : _lSurfaceVar;
  static Color get onAccent => _isDark ? _dOnAccent : _lOnAccent;
}

// ── Theme builders ──────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors._lOnSurface,
      onPrimary: AppColors._lSurface,
      primaryContainer: AppColors._lSurfaceVar,
      onPrimaryContainer: AppColors._lOnSurface,
      secondary: AppColors._lAccent,
      onSecondary: AppColors._lSurface,
      secondaryContainer: AppColors._lAccentSoft,
      onSecondaryContainer: AppColors._lAccent,
      surface: AppColors._lSurface,
      surfaceContainerHighest: AppColors._lSurfaceVar,
      error: AppColors._lError,
      onSurface: AppColors._lOnSurface,
      onSurfaceVariant: AppColors._lOnSurfaceVar,
      outline: AppColors._lOutline,
      onError: AppColors._lSurface,
    ),
    scaffoldBackgroundColor: AppColors._lBackground,
    dividerColor: AppColors._lOutline,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    textTheme: buildAppTextTheme(base.textTheme),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors._dOnSurface,
      onPrimary: AppColors._dSurface,
      primaryContainer: AppColors._dSurfaceVar,
      onPrimaryContainer: AppColors._dOnSurface,
      secondary: AppColors._dAccent,
      onSecondary: AppColors._dSurface,
      secondaryContainer: AppColors._dAccentSoft,
      onSecondaryContainer: AppColors._dAccent,
      surface: AppColors._dSurface,
      surfaceContainerHighest: AppColors._dSurfaceVar,
      error: AppColors._dError,
      onSurface: AppColors._dOnSurface,
      onSurfaceVariant: AppColors._dOnSurfaceVar,
      outline: AppColors._dOutline,
      onError: AppColors._dSurface,
    ),
    scaffoldBackgroundColor: AppColors._dBckground,
    dividerColor: AppColors._dOutline,
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    textTheme: buildAppTextTheme(base.textTheme),
  );
}

TextTheme buildAppTextTheme(TextTheme base) {
  final serif = GoogleFonts.newsreaderTextTheme(base);
  final sans = GoogleFonts.instrumentSansTextTheme(base);

  return sans.copyWith(
    displayLarge: serif.displayLarge?.copyWith(
      fontSize: 46,
      fontWeight: FontWeight.w500,
      height: 1.05,
      letterSpacing: -0.03,
    ),
    displayMedium: serif.displayMedium?.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w500,
      height: 1.05,
      letterSpacing: -0.03,
    ),
    headlineMedium: serif.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.02,
    ),
    titleLarge: sans.titleLarge?.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.01,
    ),
    bodyLarge: sans.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.65,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: sans.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

// ── Context helpers ─────────────────────────────────────────────────

extension AppThemeX on BuildContext {
  Color get appSurface => AppColors.surface;
  Color get appBackground => AppColors.background;
  Color get appOnSurface => AppColors.onSurface;
  Color get appOnSurfaceVariant => AppColors.onSurfaceVariant;
  Color get appSurfaceVariant => AppColors.surfaceVariant;
  Color get appAccent => AppColors.accent;
  Color get appAccentSoft => AppColors.accentSoft;
  Color get appOnAccent => AppColors.onAccent;
  TextTheme get appTextTheme => Theme.of(this).textTheme;
}
