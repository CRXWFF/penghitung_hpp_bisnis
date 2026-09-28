import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:penghitung_hpp_bisnis/core/database/database.dart';
import 'package:penghitung_hpp_bisnis/core/domain/models.dart';
import 'package:penghitung_hpp_bisnis/core/units/hpp_calculator.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit_conversion_service.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/data/calculation_repository.dart';
import 'package:penghitung_hpp_bisnis/features/calculations/domain/recipe_cost_service.dart';
import 'package:penghitung_hpp_bisnis/features/ingredients/data/ingredient_repository.dart';
import 'package:penghitung_hpp_bisnis/features/recipes/data/recipe_repository.dart';
import 'package:penghitung_hpp_bisnis/features/settings/data/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) =>
    IngredientRepository(ref.watch(databaseProvider)));

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) =>
    RecipeRepository(ref.watch(databaseProvider)));

final calculationRepositoryProvider = Provider<CalculationRepository>((ref) =>
    CalculationRepository(ref.watch(databaseProvider)));

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) =>
    SettingsRepository(ref.watch(databaseProvider)));

/// Pure services (no DB). Can be reused in unit tests.
final hppCalculatorProvider = Provider<HppCalculator>((ref) => const HppCalculator());
final unitConversionProvider = Provider<UnitConversionService>((ref) => const UnitConversionService());

/// Domain service that composes repositories + calculator.
final recipeCostServiceProvider = Provider<RecipeCostService>((ref) =>
    RecipeCostService(
      ref.watch(recipeRepositoryProvider),
      ref.watch(calculationRepositoryProvider),
    ));

/// Settings are async-loaded once at startup, then kept in a simple StateProvider.
final appSettingsProvider = StateProvider<AppSettings>((ref) => const AppSettings());