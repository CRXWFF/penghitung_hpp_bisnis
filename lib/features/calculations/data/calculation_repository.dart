import 'package:drift/drift.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';

/// A stored snapshot plus the recipe fields needed to display it.
typedef CalculationEntry = (Calculation calculation, String recipeName, String yieldUnitSymbol);

class CalculationRepository {
  final AppDatabase _db;
  const CalculationRepository(this._db);

  Stream<List<CalculationEntry>> watchAll() {
    final query = _db.select(_db.calculations).join([
      innerJoin(_db.recipes, _db.recipes.id.equalsExp(_db.calculations.recipeId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.calculations.createdAt)]);
    return query.watch().map((rows) => rows.map((row) {
          final calc = row.readTable(_db.calculations);
          final recipe = row.readTable(_db.recipes);
          return (calc, recipe.name, recipe.yieldUnit);
        }).toList());
  }

  Future<CalculationEntry?> getEntryById(int id) async {
    final row = await (_db.select(_db.calculations)
          ..where((t) => t.id.equals(id)))
        .join([innerJoin(_db.recipes, _db.recipes.id.equalsExp(_db.calculations.recipeId))])
        .getSingleOrNull();
    if (row == null) return null;
    return (
      row.readTable(_db.calculations),
      row.readTable(_db.recipes).name,
      row.readTable(_db.recipes).yieldUnit,
    );
  }

  /// Inserts a full calculation snapshot with its line items.
  Future<int> insertSnapshot(CalculationDraft draft) {
    return _db.transaction(() async {
      final calcId = await _db.into(_db.calculations).insert(
            CalculationsCompanion.insert(
              recipeId: draft.recipeId,
              totalMaterialCost: draft.totalMaterialCost,
              totalAdditionalCost: draft.totalAdditionalCost,
              totalCost: draft.totalCost,
              yieldQuantity: draft.yieldQuantity,
              hppPerUnit: draft.hppPerUnit,
              sellingPrice: Value(draft.sellingPrice),
              pricingMethod: Value(draft.pricingMethod),
              pricingPercentage: Value(draft.pricingPercentage),
            ),
          );
      if (draft.items.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.calculationItems,
            draft.items
                .map((i) => CalculationItemsCompanion.insert(
                      calculationId: calcId,
                      name: i.name,
                      quantity: i.quantity,
                      unit: i.unitSymbol,
                      unitCost: i.unitCost,
                      totalCost: i.totalCost,
                    ))
                .toList(),
          );
        });
      }
      return calcId;
    });
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.calculations)..where((t) => t.id.equals(id))).go();
  }

  /// For history detail: snapshot with its cost items.
  Future<(CalculationEntry, List<CalculationItem>)?> getWithItems(int id) async {
    final entry = await getEntryById(id);
    if (entry == null) return null;
    final items = await (_db.select(_db.calculationItems)
          ..where((t) => t.calculationId.equals(id)))
        .get();
    return (entry, items);
  }
}

class CalculationDraft {
  const CalculationDraft({
    required this.recipeId,
    required this.totalMaterialCost,
    required this.totalAdditionalCost,
    required this.totalCost,
    required this.yieldQuantity,
    required this.hppPerUnit,
    this.sellingPrice,
    this.pricingMethod,
    this.pricingPercentage,
    this.items = const [],
  });

  final int recipeId;
  final double totalMaterialCost;
  final double totalAdditionalCost;
  final double totalCost;
  final double yieldQuantity;
  final double hppPerUnit;
  final double? sellingPrice;
  final String? pricingMethod;
  final double? pricingPercentage;
  final List<CalculationItemDraft> items;
}

class CalculationItemDraft {
  const CalculationItemDraft({
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