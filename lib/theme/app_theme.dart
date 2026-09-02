import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Light theme base values ───────────────────────────────────────
  static const _lPrimary = Color(0xFF0F766E);
  static const _lPrimaryDark = Color(0xFF115E59);
  static const _lPrimaryLight = Color(0xFF2DD4BF);
  static const _lSecondary = Color(0xFF0EA5E9);
  static const _lSecondaryDark = Color(0xFF0284C7);
  static const _lBackground = Color(0xFFF4F6F5);
  static const _lSurface = Color(0xFFFFFFFF);
  static const _lOnSurface = Color(0xFF11211E);
  static const _lOnSurfaceVar = Color(0xFF5C6F6A);
  static const _lOutline = Color(0xFFE0E7E5);
  static const _lError = Color(0xFFEF4444);
  static const _lWarning = Color(0xFFF59E0B);
  static const _lSuccess = Color(0xFF10B981);
  static const _lSurfaceVar = Color(0xFFE9F1EF);
  static const _lCardBorder = Color(0xFFE2EAE8);

  static const gradientStart = Color(0xFF134E4A);
  static const gradientMid = Color(0xFF0F766E);
  static const gradientEnd = Color(0xFF14B8A6);
  static const gradientAccent = Color(0xFF99F6E4);

  // ── Runtime brightness flag ────────────────────────────────────────
  static bool _isDark = false;

  static void setThemeBrightness(Brightness b) =>
      _isDark = b == Brightness.dark;

  // ── Theme-aware getters ────────────────────────────────────────────
  static Color get primary => _isDark ? DarkColors.primary : _lPrimary;
  static Color get primaryDark => _isDark ? DarkColors.primaryDark : _lPrimaryDark;
  static Color get primaryLight => _isDark ? DarkColors.primaryLight : _lPrimaryLight;
  static Color get secondary => _isDark ? DarkColors.secondary : _lSecondary;
  static Color get secondaryDark => _isDark ? DarkColors.secondaryDark : _lSecondaryDark;
  static Color get background => _isDark ? DarkColors.background : _lBackground;
  static Color get surface => _isDark ? DarkColors.surface : _lSurface;
  static Color get onSurface => _isDark ? DarkColors.onSurface : _lOnSurface;
  static Color get onSurfaceVariant => _isDark ? DarkColors.onSurfaceVariant : _lOnSurfaceVar;
  static Color get outline => _isDark ? DarkColors.outline : _lOutline;
  static Color get error => _isDark ? DarkColors.error : _lError;
  static Color get warning => _isDark ? DarkColors.warning : _lWarning;
  static Color get success => _isDark ? DarkColors.success : _lSuccess;
  static Color get surfaceVariant => _isDark ? DarkColors.surfaceVariant : _lSurfaceVar;
  static Color get cardBorder => _isDark ? DarkColors.cardBorder : _lCardBorder;
}

class DarkColors {
  DarkColors._();

  static const primary = Color(0xFF5EEAD4);
  static const primaryDark = Color(0xFF14B8A6);
  static const primaryLight = Color(0xFF99F6E4);
  static const secondary = Color(0xFF38BDF8);
  static const secondaryDark = Color(0xFF0EA5E9);
  static const background = Color(0xFF0A1413);
  static const surface = Color(0xFF12201E);
  static const onSurface = Color(0xFFE6F1EF);
  static const onSurfaceVariant = Color(0xFF7D938E);
  static const outline = Color(0xFF1E322F);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const success = Color(0xFF34D399);
  static const surfaceVariant = Color(0xFF182A27);
  static const cardBorder = Color(0xFF1E322F);
}

// ── Theme builders ──────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors._lPrimary,
      primaryContainer: AppColors._lPrimaryLight,
      secondary: AppColors._lSecondary,
      secondaryContainer: AppColors._lPrimaryLight,
      surface: AppColors._lSurface,
      surfaceContainerHighest: AppColors._lSurfaceVar,
      error: AppColors._lError,
      onPrimary: Colors.white,
      onSurface: AppColors._lOnSurface,
      onSurfaceVariant: AppColors._lOnSurfaceVar,
      outline: AppColors._lOutline,
      onSecondary: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors._lBackground,
    dividerColor: AppColors._lOutline,
    splashFactory: InkSparkle.splashFactory,
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
      primary: DarkColors.primary,
      primaryContainer: DarkColors.primaryDark,
      secondary: DarkColors.secondary,
      secondaryContainer: DarkColors.primaryDark,
      surface: DarkColors.surface,
      surfaceContainerHighest: DarkColors.surfaceVariant,
      error: DarkColors.error,
      onPrimary: const Color(0xFF062B26),
      onSurface: DarkColors.onSurface,
      onSurfaceVariant: DarkColors.onSurfaceVariant,
      outline: DarkColors.outline,
      onSecondary: const Color(0xFF082F49),
      onError: const Color(0xFF450A0A),
    ),
    scaffoldBackgroundColor: DarkColors.background,
    dividerColor: DarkColors.outline,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: buildAppTextTheme(base.textTheme),
  );
}

TextTheme buildAppTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.45,
      color: AppColors.onSurfaceVariant,
    ),
  );
}

// ── Context helpers ─────────────────────────────────────────────────

extension AppThemeX on BuildContext {
  Color get appSurface => AppColors.surface;
  Color get appBackground => AppColors.background;
  Color get appOnSurface => AppColors.onSurface;
  Color get appPrimary => AppColors.primary;
  Color get appAccent => AppColors.gradientAccent;
  TextTheme get appTextTheme => Theme.of(this).textTheme;
}