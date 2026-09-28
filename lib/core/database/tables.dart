import 'package:drift/drift.dart';

/// All tables use canonical units internally. UI converts for display only.

/// Bahan baku + harga pembelian.
class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get category => text().nullable()();
  TextColumn get baseUnit => text().withLength(min: 1, max: 20)(); // canonical symbol
  RealColumn get purchaseQuantity => real()();
  TextColumn get purchaseUnit => text().withLength(min: 1, max: 20)(); // user-entered unit
  RealColumn get purchasePrice => real()(); // total price for purchaseQuantity
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Resep utama.
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  RealColumn get yieldQuantity => real()();
  TextColumn get yieldUnit => text().withLength(min: 1, max: 20)(); // canonical symbol
  TextColumn get instructions => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Komposisi resep (bahan + jumlah).
class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get ingredientId => integer().references(Ingredients, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withLength(min: 1, max: 20)(); // canonical symbol
  TextColumn get notes => text().nullable()();
}

/// Biaya tambahan produksi per resep.
class RecipeCosts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
TextColumn get type => text().withLength(min: 1, max: 20)(); // gas, electricity, water, labor, packaging, other
}

/// Snapshot kalkulasi HPP (historis, tidak berubah saat harga bahan berubah).
class Calculations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get recipeId => integer().references(Recipes, #id, onDelete: KeyAction.cascade)();
  RealColumn get totalMaterialCost => real()();
  RealColumn get totalAdditionalCost => real()();
  RealColumn get totalCost => real()();
  RealColumn get yieldQuantity => real()();
  RealColumn get hppPerUnit => real()();
  RealColumn get sellingPrice => real().nullable()();
  TextColumn get pricingMethod => text().nullable()(); // 'margin' | 'markup'
  RealColumn get pricingPercentage => real().nullable()(); // 0.3 = 30%
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Item-item biaya dalam snapshot kalkulasi.
class CalculationItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get calculationId => integer().references(Calculations, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withLength(min: 1, max: 20)(); // canonical symbol
  RealColumn get unitCost => real()(); // per canonical unit
  RealColumn get totalCost => real()();
}

/// Settings key-value.
class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 50)();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}