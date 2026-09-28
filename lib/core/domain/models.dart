/// Shared domain enums and join types.
///
/// Data rows come straight from Drift's generated classes (plain Dart, no
/// dependency on the DB layer at runtime) so there is exactly one model per
/// entity instead of a hand-written duplicate plus mapping code.
library;

import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';

enum CostType { gas, electricity, water, labor, packaging, other }

/// How a selling price is derived from HPP (PRD section 23).
enum PricingMethod { margin, markup }

extension CostTypeLabel on CostType {
  String get label => switch (this) {
        CostType.gas => 'Gas',
        CostType.electricity => 'Listrik',
        CostType.water => 'Air',
        CostType.labor => 'Tenaga',
        CostType.packaging => 'Kemasan',
        CostType.other => 'Lainnya',
      };

  static CostType parse(String raw) => CostType.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => CostType.other,
      );
}

/// A recipe line joined with its ingredient, used for HPP calculation.
class RecipeLine {
  const RecipeLine({required this.ingredient, required this.quantity, required this.unit});

  final Ingredient ingredient;
  final double quantity;

  /// Unit the quantity was entered in (from recipe_ingredients.unit).
  final Unit unit;
}

enum ThemeOption { system, light, dark }

extension ThemeOptionLabel on ThemeOption {
  String get label => switch (this) {
        ThemeOption.system => 'Ikuti sistem',
        ThemeOption.light => 'Terang',
        ThemeOption.dark => 'Gelap',
      };

  static ThemeOption parse(String raw) => ThemeOption.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => ThemeOption.system,
      );
}

class AppSettings {
  const AppSettings({
    this.currency = 'IDR',
    this.unitSystem = UnitSystem.metric,
    this.themeMode = ThemeOption.system,
  });

  final String currency;
  final UnitSystem unitSystem;
  final ThemeOption themeMode;

  AppSettings copyWith({
    String? currency,
    UnitSystem? unitSystem,
    ThemeOption? themeMode,
  }) =>
      AppSettings(
        currency: currency ?? this.currency,
        unitSystem: unitSystem ?? this.unitSystem,
        themeMode: themeMode ?? this.themeMode,
      );
}
