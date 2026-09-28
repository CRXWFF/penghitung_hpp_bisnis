import 'package:drift/native.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/data/calculation_repository.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/domain/recipe_cost_service.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/data/ingredient_repository.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/data/recipe_repository.dart';
import 'package:test/test.dart';

/// End-to-end check of the PRD section 50 example, plus the snapshot
/// immutability rule from section 25.
void main() {
  late AppDatabase db;
  late IngredientRepository ingredients;
  late RecipeRepository recipes;
  late CalculationRepository calculations;
  late RecipeCostService service;

  Future<int> addIngredient({
    required String name,
    required double qty,
    required String unit,
    required double price,
  }) {
    return ingredients.insert(IngredientDraft(
      name: name,
      baseUnitSymbol: 'g',
      purchaseQuantity: qty,
      purchaseUnitSymbol: unit,
      purchasePrice: price,
    ));
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingredients = IngredientRepository(db);
    recipes = RecipeRepository(db);
    calculations = CalculationRepository(db);
    service = RecipeCostService(recipes, calculations);
  });

  tearDown(() => db.close());

  test('PRD example 50: Brownies HPP = Rp1.890 / pcs', () async {
    final tepung = await addIngredient(name: 'Tepung', qty: 1, unit: 'kg', price: 14000);
    final telur = await addIngredient(name: 'Telur', qty: 1, unit: 'kg', price: 30000);
    final gula = await addIngredient(name: 'Gula', qty: 1, unit: 'kg', price: 16000);

    final recipeId = await recipes.insert(RecipeDraft(
      name: 'Brownies',
      yieldQuantity: 10,
      yieldUnitSymbol: 'pcs',
      lines: [
        RecipeLineDraft(ingredientId: tepung, quantity: 250, unitSymbol: 'g'),
        RecipeLineDraft(ingredientId: telur, quantity: 200, unitSymbol: 'g'),
        RecipeLineDraft(ingredientId: gula, quantity: 150, unitSymbol: 'g'),
      ],
      costs: [
        RecipeCostDraft(name: 'Listrik', amount: 2000, type: CostType.electricity),
        RecipeCostDraft(name: 'Kemasan', amount: 5000, type: CostType.packaging),
      ],
    ));

    final b = await service.breakdown(recipeId);

    // 250 x Rp14 = 3500, 200 x Rp30 = 6000, 150 x Rp16 = 2400
    expect(b.materialCost, closeTo(11900, 0.01));
    expect(b.additionalCost, closeTo(7000, 0.01));
    expect(b.totalCost, closeTo(18900, 0.01));
    expect(b.hppPerUnit, closeTo(1890, 0.01));
  });

  test('unit conversion: recipe in kg costs the same as in g', () async {
    final ids = await addIngredient(name: 'Tepung', qty: 1, unit: 'kg', price: 14000);

    final inGrams = await recipes.insert(RecipeDraft(
      name: 'R Gram',
      yieldQuantity: 1,
      yieldUnitSymbol: 'pcs',
      lines: [RecipeLineDraft(ingredientId: ids, quantity: 250, unitSymbol: 'g')],
    ));
    final inKg = await recipes.insert(RecipeDraft(
      name: 'R Kg',
      yieldQuantity: 1,
      yieldUnitSymbol: 'pcs',
      lines: [RecipeLineDraft(ingredientId: ids, quantity: 0.25, unitSymbol: 'kg')],
    ));

    expect((await service.breakdown(inGrams)).materialCost, closeTo(3500, 0.01));
    expect((await service.breakdown(inKg)).materialCost, closeTo(3500, 0.01));
  });

  test('snapshot does not change when ingredient price later changes (PRD 25)', () async {
    final id = await addIngredient(name: 'Tepung', qty: 1, unit: 'kg', price: 14000);
    final recipeId = await recipes.insert(RecipeDraft(
      name: 'Ayam Geprek',
      yieldQuantity: 10,
      yieldUnitSymbol: 'porsi',
      lines: [RecipeLineDraft(ingredientId: id, quantity: 250, unitSymbol: 'g')],
    ));

    // 1 September: price 14.000/kg
    final first = await service.breakdown(recipeId);
    expect(first.hppPerUnit, closeTo(350, 0.01));
    final snapshotId = await service.saveSnapshot(
      first,
      method: PricingMethod.margin,
      percentage: 0.3,
    );

    // 20 September: price rises to 17.000/kg
    await ingredients.update(id, const IngredientDraft(
      name: 'Tepung',
      baseUnitSymbol: 'g',
      purchaseQuantity: 1,
      purchaseUnitSymbol: 'kg',
      purchasePrice: 17000,
    ));

    // Live breakdown reflects the new price: 250 x 17 = 4250
    final second = await service.breakdown(recipeId);
    expect(second.hppPerUnit, closeTo(425, 0.01));

    // The stored snapshot is untouched.
    final stored = await calculations.getWithItems(snapshotId);
    expect(stored, isNotNull);
    final (entry, items) = stored!;
    expect(entry.$1.hppPerUnit, closeTo(350, 0.01));
    expect(entry.$1.totalMaterialCost, closeTo(3500, 0.01));
    expect(items.single.totalCost, closeTo(3500, 0.01));
    expect(items.single.unitCost, closeTo(14, 0.01));
  });

  test('selling price via margin matches PRD section 23', () async {
    expect(
      service.sellingPrice(hppPerUnit: 10000, method: PricingMethod.margin, percentage: 0.3),
      closeTo(14285.71, 0.01),
    );
    expect(
      service.sellingPrice(hppPerUnit: 10000, method: PricingMethod.markup, percentage: 0.3),
      closeTo(13000, 0.01),
    );
  });

  test('deleting a recipe cascades to lines, costs, and calculations', () async {
    final id = await addIngredient(name: 'Gula', qty: 1, unit: 'kg', price: 16000);
    final recipeId = await recipes.insert(RecipeDraft(
      name: 'Kue',
      yieldQuantity: 4,
      yieldUnitSymbol: 'pcs',
      lines: [RecipeLineDraft(ingredientId: id, quantity: 100, unitSymbol: 'g')],
      costs: [const RecipeCostDraft(name: 'Gas', amount: 1000, type: CostType.gas)],
    ));
    await service.saveSnapshot(await service.breakdown(recipeId));

    expect(await recipes.getLines(recipeId), hasLength(1));
    await recipes.delete(recipeId);

    expect(await recipes.getLines(recipeId), isEmpty);
    expect(await recipes.getCosts(recipeId), isEmpty);
    final history = await calculations.watchAll().first;
    expect(history, isEmpty);
  });

  test('ingredient with zero purchase quantity is rejected', () {
    expect(
      () => ingredients.insert(const IngredientDraft(
        name: 'X',
        baseUnitSymbol: 'g',
        purchaseQuantity: 0,
        purchaseUnitSymbol: 'kg',
        purchasePrice: 1000,
      )),
      throwsArgumentError,
    );
  });

  test('recipe with zero yield is rejected', () {
    expect(
      () => recipes.insert(const RecipeDraft(
        name: 'X',
        yieldQuantity: 0,
        yieldUnitSymbol: 'pcs',
      )),
      throwsArgumentError,
    );
  });
}
