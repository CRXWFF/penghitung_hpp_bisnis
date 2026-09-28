import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
/// DESIGN.md typography + shape + spacing.
class AppTheme {
  const AppTheme._();

  /// DESIGN.md: display-lg 32/40 700 -0.02em
  static TextStyle _displayLarge(TextStyle base) => base.copyWith(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
      );

  /// headline-lg 24/32 600 -0.01em
  static TextStyle _headlineLarge(TextStyle base) => base.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 24,
      );

  /// headline-sm 18/24 600
  static TextStyle _headlineSmall(TextStyle base) => base.copyWith(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
      );

  /// title-md 16/22 600
  static TextStyle _titleMedium(TextStyle base) => base.copyWith(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
      );

  /// body-lg 16/24 400
  static TextStyle _bodyLarge(TextStyle base) => base.copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      );

  /// body-md 14/20 400
  static TextStyle _bodyMedium(TextStyle base) => base.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      );

  /// body-sm 12/16 400
  static TextStyle _bodySmall(TextStyle base) => base.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
      );

  /// Inter label-numeric 15/20 600 - tabular (DESIGN.md: all IDR/currency use
  /// Inter with tabular figures so cost columns don't jitter).
  static TextStyle numeric({
    double? size,
    Color? color,
    FontWeight? weight,
  }) {
    return GoogleFonts.inter(
      fontSize: size ?? 15,
      height: 20 / 15,
      fontWeight: weight ?? FontWeight.w600,
      letterSpacing: 0.01 * 15,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Inter label-sm 10/14 600 0.04em (chips, pills, captions)
  static TextStyle labelSmall({Color? color, FontWeight? weight, double? size}) {
    return GoogleFonts.inter(
      fontSize: size ?? 10,
      height: 14 / 10,
      fontWeight: weight ?? FontWeight.w600,
      letterSpacing: 0.04 * 10,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Inter label-md 12/16 600 0.02em (buttons, labels)
  static TextStyle labelMedium({Color? color, FontWeight? weight}) {
    return GoogleFonts.inter(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: weight ?? FontWeight.w600,
      letterSpacing: 0.02 * 12,
      color: color,
    );
  }

  static ThemeData light() => _build(lightColorScheme);
  static ThemeData dark() => _build(darkColorScheme);

  static ThemeData _build(ColorScheme scheme) {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme();
    final inter = GoogleFonts.interTextTheme();

    final textTheme = TextTheme(
      displayLarge: _displayLarge(jakarta.displayLarge!),
      headlineLarge: _headlineLarge(jakarta.headlineLarge!),
      headlineMedium: _headlineLarge(jakarta.headlineMedium!),
      headlineSmall: _headlineSmall(jakarta.headlineSmall!),
      titleLarge: _titleMedium(jakarta.titleLarge!),
      titleMedium: _titleMedium(jakarta.titleMedium!),
      titleSmall: _titleMedium(jakarta.titleSmall!),
      bodyLarge: _bodyLarge(jakarta.bodyLarge!),
      bodyMedium: _bodyMedium(jakarta.bodyMedium!),
      bodySmall: _bodySmall(jakarta.bodySmall!),
      labelLarge: _bodyMedium(inter.labelLarge!),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _titleMedium(textTheme.titleMedium!).copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        // DESIGN.md: tonal elevation, no harsh drop shadows
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide.none,
        labelStyle: _bodySmall(textTheme.bodySmall!).copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: _bodySmall(textTheme.bodySmall!).copyWith(color: scheme.onSurfaceVariant),
        hintStyle: _bodyMedium(textTheme.bodyMedium!).copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: _bodySmall(textTheme.bodySmall!).copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          // DESIGN.md: 48px height, 14px radius
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: _titleMedium(textTheme.titleMedium!),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: _bodyMedium(textTheme.bodyMedium!),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: _bodyMedium(textTheme.bodyMedium!),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: _bodyMedium(textTheme.bodyMedium!).copyWith(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: _titleMedium(textTheme.titleMedium!),
        subtitleTextStyle: _bodySmall(textTheme.bodySmall!).copyWith(color: scheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      ),
    );
  }
}
