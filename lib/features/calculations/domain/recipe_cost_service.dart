import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/units/hpp_calculator.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit_conversion_service.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/data/calculation_repository.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/data/recipe_repository.dart';

/// One costed recipe line, ready for display and for the snapshot.
class CostedLine {
  const CostedLine({
    required this.name,
    required this.quantity,
    required this.unitSymbol,
    required this.unitCost,
    required this.totalCost,
  });

  final String name;
  final double quantity;
  final String unitSymbol;
  final double unitCost;
  final double totalCost;
}

class CostedCost {
  const CostedCost({required this.name, required this.amount});

  final String name;
  final double amount;
}

/// Full recipe cost breakdown. Pure output of HppCalculator + repository lines.
class RecipeBreakdown {
  const RecipeBreakdown({
    required this.recipe,
    required this.lines,
    required this.costs,
    required this.materialCost,
    required this.additionalCost,
    required this.totalCost,
    required this.hppPerUnit,
  });

  final Recipe recipe;
  final List<CostedLine> lines;
  final List<CostedCost> costs;
  final double materialCost;
  final double additionalCost;
  final double totalCost;
  final double hppPerUnit;
}

/// Orchestrates repository reads + HppCalculator. Holds no Flutter state.
class RecipeCostService {
  final RecipeRepository _recipes;
  final CalculationRepository _calculations;
  final HppCalculator _calc = const HppCalculator();
  final UnitConversionService _units = const UnitConversionService();

  const RecipeCostService(this._recipes, this._calculations);

  /// Costed lines only, for live preview while editing prices.
  List<CostedLine> costLines(List<RecipeLine> recipeLines) {
    final out = <CostedLine>[];
    for (final line in recipeLines) {
      final base = Unit.parse(line.ingredient.baseUnit);
      if (base == null) continue;
      if (base.kind != line.unit.kind) continue;
      final perBase = pricePerBaseUnit(line.ingredient);
      if (perBase == null) continue;
      final qtyInBase = _units.convert(line.quantity, line.unit, base) ?? line.quantity;
      out.add(CostedLine(
        name: line.ingredient.name,
        quantity: line.quantity,
        unitSymbol: line.ingredient.baseUnit,
        unitCost: perBase,
        totalCost: qtyInBase * perBase,
      ));
    }
    return out;
  }

  /// Price per canonical unit. `purchasePrice` covers the whole
  /// `purchaseQuantity` in its own purchase unit, so that quantity must be
  /// converted to the base unit first: 1 kg for Rp14.000 with baseUnit "g"
  /// is Rp14/gram, not Rp14.000/gram.
  double? pricePerBaseUnit(Ingredient ingredient) {
    if (ingredient.purchaseQuantity <= 0) return null;
    final base = Unit.parse(ingredient.baseUnit);
    final purchase = Unit.parse(ingredient.purchaseUnit);
    if (base == null || purchase == null || base.kind != purchase.kind) return null;
    final qtyInBase = _units.convert(ingredient.purchaseQuantity, purchase, base);
    if (qtyInBase == null || qtyInBase <= 0) return null;
    return ingredient.purchasePrice / qtyInBase;
  }

  /// Full breakdown for a saved recipe.
  Future<RecipeBreakdown> breakdown(int recipeId) async {
    final recipe = await _recipes.getById(recipeId);
    if (recipe == null) throw StateError('Resep tidak ditemukan');

    final lines = await _recipes.getLines(recipeId);
    final costs = await _recipes.getCosts(recipeId);

    final costed = costLines(lines);
    final costedCosts = costs
        .where((c) => c.amount > 0)
        .map((c) => CostedCost(name: c.name, amount: c.amount))
        .toList();

    final materialCost = _calc.calculateMaterialCost(
      costed.map((c) => IngredientCostResult(
            quantity: c.quantity,
            unit: Unit.parse(c.unitSymbol)!,
            unitCost: c.unitCost,
            totalCost: c.totalCost,
          )).toList(),
    );
    final additionalCost =
        _calc.calculateAdditionalCost({for (final c in costedCosts) c.name: c.amount});
    final totalCost = _calc.calculateTotalRecipeCost(
      materialCost: materialCost,
      additionalCost: additionalCost,
    );
    final hpp = _calc.calculateHppPerUnit(
      totalCost: totalCost,
      yieldQuantity: recipe.yieldQuantity,
    );

    return RecipeBreakdown(
      recipe: recipe,
      lines: costed,
      costs: costedCosts,
      materialCost: materialCost,
      additionalCost: additionalCost,
      totalCost: totalCost,
      hppPerUnit: hpp,
    );
  }

  /// Persists a snapshot. Historical values never change afterwards, even if
  /// ingredient prices are updated later.
  Future<int> saveSnapshot(
    RecipeBreakdown b, {
    PricingMethod? method,
    double? percentage,
  }) async {
    double? sellingPrice;
    if (method != null && percentage != null) {
      sellingPrice = switch (method) {
        PricingMethod.margin => _calc.calculateMarginPrice(hppPerUnit: b.hppPerUnit, margin: percentage),
        PricingMethod.markup => _calc.calculateMarkupPrice(hppPerUnit: b.hppPerUnit, markup: percentage),
      };
    }
    return _calculations.insertSnapshot(
      CalculationDraft(
        recipeId: b.recipe.id,
        totalMaterialCost: b.materialCost,
        totalAdditionalCost: b.additionalCost,
        totalCost: b.totalCost,
        yieldQuantity: b.recipe.yieldQuantity,
        hppPerUnit: b.hppPerUnit,
        sellingPrice: sellingPrice,
        pricingMethod: method?.name,
        pricingPercentage: percentage,
        items: b.lines
            .map((l) => CalculationItemDraft(
                  name: l.name,
                  quantity: l.quantity,
                  unitSymbol: l.unitSymbol,
                  unitCost: l.unitCost,
                  totalCost: l.totalCost,
                ))
            .toList(),
      ),
    );
  }

  /// Selling price for the pricing calculator screen.
  double sellingPrice({required double hppPerUnit, required PricingMethod method, required double percentage}) {
    return switch (method) {
      PricingMethod.margin => _calc.calculateMarginPrice(hppPerUnit: hppPerUnit, margin: percentage),
      PricingMethod.markup => _calc.calculateMarkupPrice(hppPerUnit: hppPerUnit, markup: percentage),
    };
  }
}