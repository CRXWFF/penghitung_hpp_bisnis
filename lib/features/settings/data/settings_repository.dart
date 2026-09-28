import 'package:drift/drift.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';

class SettingsRepository {
  final AppDatabase _db;
  const SettingsRepository(this._db);

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final map = {for (var r in rows) r.key: r.value};
    return AppSettings(
      currency: map['currency'] ?? 'IDR',
      unitSystem: UnitSystem.values.firstWhere(
        (e) => e.name == (map['unitSystem'] ?? 'metric'),
        orElse: () => UnitSystem.metric,
      ),
      themeMode: ThemeOptionLabel.parse(map['theme'] ?? 'system'),
    );
  }

  Future<void> save(AppSettings s) => _db.batch((batch) {
        batch.insertAll(
          _db.settings,
          [
            SettingsCompanion.insert(key: 'currency', value: s.currency),
            SettingsCompanion.insert(key: 'unitSystem', value: s.unitSystem.name),
            SettingsCompanion.insert(key: 'theme', value: s.themeMode.name),
          ],
          mode: InsertMode.insertOrReplace,
        );
      });

  Future<void> setCurrency(String code) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'currency', value: code),
        );
  }

  Future<void> setUnitSystem(UnitSystem system) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'unitSystem', value: system.name),
        );
  }

  Future<void> setTheme(ThemeOption theme) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: 'theme', value: theme.name),
        );
  }
}