import 'package:flutter/material.dart';

/// Semantic color pairs from the mocks, resolved per brightness so no
/// light-only color leaks into dark mode.
///
/// Deliberately NOT a ThemeExtension: a real ThemeExtension would need a
/// 30-field copyWith + lerp, and nothing here interpolates at runtime —
/// we only ever pick light or dark whole. ponytail: switch to a
/// ThemeExtension if per-widget color animation is ever needed.
class AppPalette {
  const AppPalette._({
    required this.cardBg,
    required this.cardAltBg,
    required this.cardOn,
    required this.pillPrimaryBg,
    required this.pillPrimaryOn,
    required this.pillSecondaryBg,
    required this.pillSecondaryOn,
    required this.pillTertiaryBg,
    required this.pillTertiaryOn,
    required this.pillSurfaceVariantBg,
    required this.pillSurfaceVariantOn,
    required this.highlightBgStart,
    required this.highlightBgEnd,
    required this.highlightOn,
    required this.highlightOnVariant,
    required this.noticeBg,
    required this.noticeOn,
    required this.noticeOnVariant,
    required this.marginHighBg,
    required this.marginHighOn,
    required this.marginMidBg,
    required this.marginMidOn,
    required this.marginLowBg,
    required this.marginLowOn,
    required this.iconTileBg,
    required this.iconTileOn,
    required this.priceRoundedBg,
    required this.priceRoundedOn,
    required this.priceExactBg,
    required this.priceExactOn,
    required this.linkColor,
  });

  final Color cardBg;
  final Color cardAltBg;
  final Color cardOn;

  final Color pillPrimaryBg;
  final Color pillPrimaryOn;
  final Color pillSecondaryBg;
  final Color pillSecondaryOn;
  final Color pillTertiaryBg;
  final Color pillTertiaryOn;
  final Color pillSurfaceVariantBg;
  final Color pillSurfaceVariantOn;

  final Color highlightBgStart;
  final Color highlightBgEnd;
  final Color highlightOn;
  final Color highlightOnVariant;

  final Color noticeBg;
  final Color noticeOn;
  final Color noticeOnVariant;

  final Color marginHighBg;
  final Color marginHighOn;
  final Color marginMidBg;
  final Color marginMidOn;
  final Color marginLowBg;
  final Color marginLowOn;

  final Color iconTileBg;
  final Color iconTileOn;

  final Color priceRoundedBg;
  final Color priceRoundedOn;
  final Color priceExactBg;
  final Color priceExactOn;

  final Color linkColor;

  /// Margin band per DESIGN.md: >=40% healthy, 25-39% watch, <25% thin.
  (Color, Color) marginBand(double fraction) {
    final pct = (fraction * 100).round();
    if (pct >= 40) return (marginHighBg, marginHighOn);
    if (pct >= 25) return (marginMidBg, marginMidOn);
    return (marginLowBg, marginLowOn);
  }

  static const _light = AppPalette._(
    cardBg: Color(0xFFFFFFFF),
    cardAltBg: Color(0xFFE7EEFF),
    cardOn: Color(0xFF111C2D),
    pillPrimaryBg: Color(0xFFFFDBCE),
    pillPrimaryOn: Color(0xFF370E00),
    pillSecondaryBg: Color(0xFFB9F079),
    pillSecondaryOn: Color(0xFF416E00),
    pillTertiaryBg: Color(0xFFFFDCC3),
    pillTertiaryOn: Color(0xFF2F1500),
    pillSurfaceVariantBg: Color(0xFFD8E3FB),
    pillSurfaceVariantOn: Color(0xFF5A4138),
    highlightBgStart: Color(0xFFFFDBCE),
    highlightBgEnd: Color(0xFFDEE8FF),
    highlightOn: Color(0xFF370E00),
    highlightOnVariant: Color(0xFF7F2B00),
    noticeBg: Color(0x33FFDBCE),
    noticeOn: Color(0xFF7F2B00),
    noticeOnVariant: Color(0xFF7F2B00),
    marginHighBg: Color(0xFFB9F079),
    marginHighOn: Color(0xFF416E00),
    marginMidBg: Color(0xFFB15F00),
    marginMidOn: Color(0xFFFFFBFF),
    marginLowBg: Color(0xFFCC4900),
    marginLowOn: Color(0xFFFFFBFF),
    iconTileBg: Color(0xFFF0F3FF),
    iconTileOn: Color(0xFFA33900),
    priceRoundedBg: Color(0x80B9F079),
    priceRoundedOn: Color(0xFF3E6A00),
    priceExactBg: Color(0xFFF0F3FF),
    priceExactOn: Color(0xFF111C2D),
    linkColor: Color(0xFFA33900),
  );

  static const _dark = AppPalette._(
    cardBg: Color(0xFF1B2030),
    cardAltBg: Color(0xFF252A38),
    cardOn: Color(0xFFE3E7F2),
    pillPrimaryBg: Color(0xFF7A2C00),
    pillPrimaryOn: Color(0xFFFFDBCB),
    pillSecondaryBg: Color(0xFF3F5A00),
    pillSecondaryOn: Color(0xFFD4FAA4),
    pillTertiaryBg: Color(0xFF6A3800),
    pillTertiaryOn: Color(0xFFFFDCC3),
    pillSurfaceVariantBg: Color(0xFF3A4054),
    pillSurfaceVariantOn: Color(0xFFA9AFC2),
    highlightBgStart: Color(0xFF7A2C00),
    highlightBgEnd: Color(0xFF30364A),
    highlightOn: Color(0xFFFFDBCB),
    highlightOnVariant: Color(0xFFD4FAA4),
    noticeBg: Color(0x33FFB599),
    noticeOn: Color(0xFFE3E7F2),
    noticeOnVariant: Color(0xFFA9AFC2),
    marginHighBg: Color(0xFFB8DD7A),
    marginHighOn: Color(0xFF213800),
    marginMidBg: Color(0xFFFFB77D),
    marginMidOn: Color(0xFF4A2400),
    marginLowBg: Color(0xFFFFB599),
    marginLowOn: Color(0xFF5A1B00),
    iconTileBg: Color(0xFF171B26),
    iconTileOn: Color(0xFFFFB599),
    priceRoundedBg: Color(0x4DB8DD7A),
    priceRoundedOn: Color(0xFFD4FAA4),
    priceExactBg: Color(0xFF252A38),
    priceExactOn: Color(0xFFE3E7F2),
    linkColor: Color(0xFFFFB599),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
