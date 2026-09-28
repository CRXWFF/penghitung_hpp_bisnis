import 'package:drift/drift.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';

class IngredientRepository {
  final AppDatabase _db;
  const IngredientRepository(this._db);

  Stream<List<Ingredient>> watchAll({String query = ''}) {
    final stmt = _db.select(_db.ingredients)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    if (query.trim().isNotEmpty) {
      stmt.where((t) => t.name.lower().like('%$query%'));
    }
    return stmt.watch();
  }

  Future<List<Ingredient>> getAll() async {
    return (_db.select(_db.ingredients)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Ingredient?> getById(int id) async {
    return (_db.select(_db.ingredients)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(IngredientDraft draft) async {
    if (draft.name.trim().isEmpty) {
      throw ArgumentError('Nama bahan wajib diisi');
    }
    if (draft.purchaseQuantity <= 0) {
      throw ArgumentError('Jumlah pembelian harus lebih dari 0');
    }
    if (draft.purchasePrice < 0) {
      throw ArgumentError('Harga pembelian tidak boleh negatif');
    }
    return _db.into(_db.ingredients).insert(
          IngredientsCompanion.insert(
            name: draft.name.trim(),
            category: Value(draft.category),
            baseUnit: draft.baseUnitSymbol,
            purchaseQuantity: draft.purchaseQuantity,
            purchaseUnit: draft.purchaseUnitSymbol,
            purchasePrice: draft.purchasePrice,
            notes: Value(draft.notes),
          ),
        );
  }

  Future<void> update(int id, IngredientDraft draft) async {
    if (draft.name.trim().isEmpty) {
      throw ArgumentError('Nama bahan wajib diisi');
    }
    if (draft.purchaseQuantity <= 0) {
      throw ArgumentError('Jumlah pembelian harus lebih dari 0');
    }
    if (draft.purchasePrice < 0) {
      throw ArgumentError('Harga pembelian tidak boleh negatif');
    }
    await (_db.update(_db.ingredients)..where((t) => t.id.equals(id))).write(
      IngredientsCompanion(
        name: Value(draft.name.trim()),
        category: Value(draft.category),
        baseUnit: Value(draft.baseUnitSymbol),
        purchaseQuantity: Value(draft.purchaseQuantity),
        purchaseUnit: Value(draft.purchaseUnitSymbol),
        purchasePrice: Value(draft.purchasePrice),
        notes: Value(draft.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.ingredients)..where((t) => t.id.equals(id))).go();
  }
}

class IngredientDraft {
  const IngredientDraft({
    required this.name,
    this.category,
    required this.baseUnitSymbol,
    required this.purchaseQuantity,
    required this.purchaseUnitSymbol,
    required this.purchasePrice,
    this.notes,
  });

  final String name;
  final String? category;
  final String baseUnitSymbol;
  final double purchaseQuantity;
  final String purchaseUnitSymbol;
  final double purchasePrice;
  final String? notes;
}