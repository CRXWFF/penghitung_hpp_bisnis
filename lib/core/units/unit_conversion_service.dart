import 'unit.dart';

/// Pure unit conversion. No Flutter deps. Easy to unit-test.
class UnitConversionService {
  const UnitConversionService();

  /// Convert [amount] from [from] to [to]. Returns null if kinds don't match.
  double? convert(double amount, Unit from, Unit to) {
    if (from.kind != to.kind) return null;
    if (from == to) return amount;
    final canonical = amount * from.toCanonical;
    return canonical / to.toCanonical;
  }

  /// Convert a recipe-ingredient amount (with its own [unit]) into the ingredient's
  /// [baseUnit] (the canonical unit the ingredient price is stored in).
  double toBaseUnit(double amount, Unit unit, Unit baseUnit) {
    if (unit.kind != baseUnit.kind) {
      throw ArgumentError('Unit kind mismatch: $unit vs $baseUnit');
    }
    return convert(amount, unit, baseUnit)!;
  }

  /// Canonical unit for a [kind] (gram / ml / cm / pcs).
  Unit canonicalFor(UnitKind kind) => switch (kind) {
        UnitKind.weight => Unit.weight.firstWhere((u) => u.symbol == 'g'),
        UnitKind.volume => Unit.volume.firstWhere((u) => u.symbol == 'ml'),
        UnitKind.length => Unit.length.firstWhere((u) => u.symbol == 'cm'),
        UnitKind.count => Unit.count.firstWhere((u) => u.symbol == 'pcs'),
      };

  /// Human-readable format: "250 g" or "1.5 kg".
  String format(double amount, Unit unit, {int precision = 2}) {
    final clean = amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(precision).replaceAll(RegExp(r'\.?0+$'), '');
    return '$clean ${unit.symbol}';
  }
}

/// Result of an ingredient cost calculation.
class IngredientCostResult {
  const IngredientCostResult({
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
  });

  final double quantity;
  final Unit unit;
  final double unitCost; // per canonical unit (gram/ml/cm/pcs)
  final double totalCost; // quantity * unitCost (already converted to base)
}