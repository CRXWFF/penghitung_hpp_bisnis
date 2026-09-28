import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Ingredients,
  Recipes,
  RecipeIngredients,
  RecipeCosts,
  Calculations,
  CalculationItems,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory instance for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        // SQLite ignores FK constraints unless this is on per connection.
        // Required for the ON DELETE CASCADE in PRD section 43.
        beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
        // ponytail: schemaVersion 1, no upgrade path yet. Add steps in onUpgrade
        // when the schema actually changes, bump schemaVersion alongside.
      );

  // --- Settings ---
  Future<String?> getSetting(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull()
          .then((row) => row?.value);

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(File(p.join(dir.path, 'hpp_manager.sqlite')));
    });