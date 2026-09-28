import 'package:drift/drift.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';

class RecipeRepository {
  final AppDatabase _db;
  const RecipeRepository(this._db);

  Stream<List<Recipe>> watchAll({String query = ''}) {
    final stmt = _db.select(_db.recipes)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (query.trim().isNotEmpty) {
      stmt.where((t) => t.name.lower().like('%$query%'));
    }
    return stmt.watch();
  }

  Stream<Recipe?> watchById(int id) {
    return (_db.select(_db.recipes)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<Recipe?> getById(int id) async {
    return (_db.select(_db.recipes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Recipe>> getAll() async {
    return (_db.select(_db.recipes)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  /// Recipe lines joined with their ingredient, for HPP calculation.
  Future<List<RecipeLine>> getLines(int recipeId) async {
    final rows = await (_db.select(_db.recipeIngredients)
          ..where((t) => t.recipeId.equals(recipeId)))
        .join([innerJoin(_db.ingredients, _db.ingredients.id.equalsExp(_db.recipeIngredients.ingredientId))])
        .get();
    return rows
        .map((row) => RecipeLine(
              ingredient: row.readTable(_db.ingredients),
              quantity: row.readTable(_db.recipeIngredients).quantity,
              unit: Unit.parse(row.readTable(_db.recipeIngredients).unit)!,
            ))
        .toList();
  }

  Future<List<RecipeCost>> getCosts(int recipeId) async {
    return (_db.select(_db.recipeCosts)..where((t) => t.recipeId.equals(recipeId))).get();
  }

  Future<int> insert(RecipeDraft draft) {
    draft.validate();
    return _db.transaction(() async {
      final id = await _db.into(_db.recipes).insert(
            RecipesCompanion.insert(
              name: draft.name,
              description: Value(draft.description),
              category: Value(draft.category),
              yieldQuantity: draft.yieldQuantity,
              yieldUnit: draft.yieldUnitSymbol,
              instructions: Value(draft.instructions),
            ),
          );
      await _writeLines(id, draft);
      return id;
    });
  }

  Future<void> update(int id, RecipeDraft draft) {
    draft.validate();
    return _db.transaction(() async {
      await (_db.update(_db.recipes)..where((t) => t.id.equals(id))).write(
        RecipesCompanion(
          name: Value(draft.name),
          description: Value(draft.description),
          category: Value(draft.category),
          yieldQuantity: Value(draft.yieldQuantity),
          yieldUnit: Value(draft.yieldUnitSymbol),
          instructions: Value(draft.instructions),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_db.delete(_db.recipeIngredients)..where((t) => t.recipeId.equals(id))).go();
      await (_db.delete(_db.recipeCosts)..where((t) => t.recipeId.equals(id))).go();
      await _writeLines(id, draft);
    });
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.recipes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> _writeLines(int recipeId, RecipeDraft draft) async {
    for (final line in draft.lines) {
      if (line.quantity <= 0) continue;
      await _db.into(_db.recipeIngredients).insert(
            RecipeIngredientsCompanion.insert(
              recipeId: recipeId,
              ingredientId: line.ingredientId,
              quantity: line.quantity,
              unit: line.unitSymbol,
            ),
          );
    }
    for (final cost in draft.costs) {
      if (cost.amount <= 0) continue;
      await _db.into(_db.recipeCosts).insert(
            RecipeCostsCompanion.insert(
              recipeId: recipeId,
              name: cost.name,
              amount: cost.amount,
              type: cost.type.name,
            ),
          );
    }
  }
}

class RecipeDraft {
  const RecipeDraft({
    required this.name,
    this.description,
    this.category,
    required this.yieldQuantity,
    required this.yieldUnitSymbol,
    this.instructions,
    this.lines = const [],
    this.costs = const [],
  });

  final String name;
  final String? description;
  final String? category;
  final double yieldQuantity;
  final String yieldUnitSymbol;
  final String? instructions;
  final List<RecipeLineDraft> lines;
  final List<RecipeCostDraft> costs;

  /// Validation gate before any DB write.
  void validate() {
    if (name.trim().isEmpty) throw ArgumentError('Nama resep wajib diisi');
    if (yieldQuantity <= 0) throw ArgumentError('Jumlah hasil produksi harus lebih dari 0');
    if (lines.isEmpty) {
      throw ArgumentError('Resep harus memiliki minimal satu bahan.\nTambahkan bahan sebelum menyimpan.');
    }
    for (final l in lines) {
      if (l.quantity <= 0) throw ArgumentError('Jumlah bahan harus lebih dari 0');
    }
    for (final c in costs) {
      if (c.amount < 0) throw ArgumentError('Biaya "${c.name}" tidak boleh negatif');
    }
  }
}

class RecipeLineDraft {
  const RecipeLineDraft({
    required this.ingredientId,
    required this.quantity,
    required this.unitSymbol,
  });

  final int ingredientId;
  final double quantity;
  final String unitSymbol;
}

class RecipeCostDraft {
  const RecipeCostDraft({required this.name, required this.amount, required this.type});

  final String name;
  final double amount;
  final CostType type;
}