import 'package:flutter/material.dart';

/// DESIGN.md frontmatter tokens.///
/// These are the *only* color values the mocks use (see screen_mock/*.html tailwind.config).
/// The prose in DESIGN.md describes a warm cream/terracotta palette that contradicts this.
/// We follow the mocks + frontmatter per user decision.
class AppColors {
  const AppColors._();

  static const surface = Color(0xFFF9F9FF);
  static const surfaceDim = Color(0xFFCFDAF2);
  static const surfaceBright = Color(0xFFF9F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF0F3FF);
  static const surfaceContainer = Color(0xFFE7EEFF);
  static const surfaceContainerHigh = Color(0xFFDEE8FF);
  static const surfaceContainerHighest = Color(0xFFD8E3FB);
  static const onSurface = Color(0xFF111C2D);
  static const onSurfaceVariant = Color(0xFF5A4138);
  static const inverseSurface = Color(0xFF263143);
  static const inverseOnSurface = Color(0xFFECF1FF);
  static const outline = Color(0xFF8E7166);
  static const outlineVariant = Color(0xFFE2BFB2);
  static const surfaceTint = Color(0xFFA73A00);
  static const primary = Color(0xFFA33900);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFCC4900);
  static const onPrimaryContainer = Color(0xFFFFFBFF);
  static const inversePrimary = Color(0xFFFFB599);
  static const secondary = Color(0xFF3E6A00);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFB9F079);
  static const onSecondaryContainer = Color(0xFF416E00);
  static const tertiary = Color(0xFF8D4B00);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFB15F00);
  static const onTertiaryContainer = Color(0xFFFFFBFF);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const primaryFixed = Color(0xFFFFDBCE);
  static const primaryFixedDim = Color(0xFFFFB599);
  static const onPrimaryFixed = Color(0xFF370E00);
  static const onPrimaryFixedVariant = Color(0xFF7F2B00);
  static const secondaryFixed = Color(0xFFBBF37C);
  static const secondaryFixedDim = Color(0xFFA0D663);
  static const onSecondaryFixed = Color(0xFF0F2000);
  static const onSecondaryFixedVariant = Color(0xFF2E4F00);
  static const tertiaryFixed = Color(0xFFFFDCC3);
  static const tertiaryFixedDim = Color(0xFFFFB77D);
  static const onTertiaryFixed = Color(0xFF2F1500);
  static const onTertiaryFixedVariant = Color(0xFF6E3900);
  static const background = Color(0xFFF9F9FF);
  static const onBackground = Color(0xFF111C2D);
  static const surfaceVariant = Color(0xFFD8E3FB);
}

/// Mapping to Material 3 ColorScheme for ThemeData.fromColorScheme().
ColorScheme get lightColorScheme => const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceTint: AppColors.surfaceTint,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceDim: AppColors.surfaceDim,
    );

/// Dark mode is not in DESIGN.md / the mocks, so this is a proper M3 dark
/// derivation of the same tokens: the blue-tinted neutral family deepens, and
/// every accent lifts to a light tone (M3 dark rule: primary/secondary/
/// tertiary get lighter, not darker, or they fail contrast on a dark canvas).
ColorScheme get darkColorScheme => const ColorScheme(
      brightness: Brightness.dark,
      // Accents: light tone on dark canvas.
      primary: Color(0xFFFFB599),
      onPrimary: Color(0xFF5A1B00),
      primaryContainer: Color(0xFF7A2C00),
      onPrimaryContainer: Color(0xFFFFDBCB),
      secondary: Color(0xFFB8DD7A),
      onSecondary: Color(0xFF213800),
      secondaryContainer: Color(0xFF3F5A00),
      onSecondaryContainer: Color(0xFFD4FAA4),
      tertiary: Color(0xFFFFB77D),
      onTertiary: Color(0xFF4A2400),
      tertiaryContainer: Color(0xFF6A3800),
      onTertiaryContainer: Color(0xFFFFDCC3),

      // Neutrals: deep blue-tinted, stepping up with elevation.
      surface: Color(0xFF10131C),
      onSurface: Color(0xFFE3E7F2),
      onSurfaceVariant: Color(0xFFA9AFC2),
      outline: Color(0xFF757B8E),
      outlineVariant: Color(0xFF3A4054),
      surfaceContainerLowest: Color(0xFF0A0D14),
      surfaceContainerLow: Color(0xFF171B26),
      surfaceContainer: Color(0xFF1B2030),
      surfaceContainerHigh: Color(0xFF252A38),
      surfaceContainerHighest: Color(0xFF30364A),
      surfaceDim: Color(0xFF10131C),
      surfaceBright: Color(0xFF363B4A),
      surfaceTint: Color(0xFFFFB599),
      inverseSurface: Color(0xFFE3E7F2),
      onInverseSurface: Color(0xFF2A2F3C),
      inversePrimary: Color(0xFFA33900),

      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    );