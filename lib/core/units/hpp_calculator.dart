import 'unit_conversion_service.dart';
import 'unit.dart';

/// Pure HPP business logic. No Flutter, no DB. All math is unit-testable.
class HppCalculator {
  const HppCalculator();

  /// Cost of a single ingredient line.
  /// [quantity] is in the ingredient's [unit]; [unitCost] is per base unit.
  /// Throws if [quantity] <= 0.
  IngredientCostResult calculateIngredientCost({
    required double quantity,
    required Unit unit,
    required double unitCost,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity harus lebih dari 0, got $quantity');
    }
    return IngredientCostResult(
      quantity: quantity,
      unit: unit,
      unitCost: unitCost,
      totalCost: quantity * unitCost,
    );
  }

  /// Sum of all ingredient costs. Ignores nulls (ingredients with no price).
  double calculateMaterialCost(List<IngredientCostResult> items) {
    return items.fold<double>(0, (sum, i) => sum + i.totalCost);
  }

  /// Sum of additional production costs. Throws on negative.
  double calculateAdditionalCost(Map<String, double> extraCosts) {
    if (extraCosts.values.any((v) => v < 0)) {
      throw ArgumentError('Biaya tambahan tidak boleh negatif');
    }
    return extraCosts.values.fold<double>(0, (sum, v) => sum + v);
  }

  /// Total recipe cost = material + additional.
  double calculateTotalRecipeCost({
    required double materialCost,
    required double additionalCost,
  }) {
    if (materialCost < 0 || additionalCost < 0) {
      throw ArgumentError('Biaya tidak boleh negatif');
    }
    return materialCost + additionalCost;
  }

  /// HPP per unit. Throws if yield <= 0.
  double calculateHppPerUnit({required double totalCost, required double yieldQuantity}) {
    if (yieldQuantity <= 0) {
      throw ArgumentError('Jumlah hasil produksi harus lebih dari 0');
    }
    return totalCost / yieldQuantity;
  }

  /// Selling price from margin: price = hpp / (1 - margin).
  /// margin is 0..1 (exclusive of 1). Throws if margin >= 1 or < 0.
  double calculateMarginPrice({required double hppPerUnit, required double margin}) {
    if (margin < 0 || margin >= 1) {
      throw ArgumentError('Margin harus antara 0 dan 100% (tidak boleh 100%)');
    }
    return hppPerUnit / (1 - margin);
  }

  /// Selling price from markup: price = hpp * (1 + markup).
  /// markup is >= 0. Throws if negative.
  double calculateMarkupPrice({required double hppPerUnit, required double markup}) {
    if (markup < 0) {
      throw ArgumentError('Markup tidak boleh negatif');
    }
    return hppPerUnit * (1 + markup);
  }
}
