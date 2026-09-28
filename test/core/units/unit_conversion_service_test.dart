import 'package:test/test.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit.dart';
import 'package:penghitung_hpp_bisnis/core/units/unit_conversion_service.dart';
import 'package:penghitung_hpp_bisnis/core/units/hpp_calculator.dart';

void main() {
  group('Unit', () {
    test('parse recognizes symbols and aliases', () {
      expect(Unit.parse('g'), Unit.weight.firstWhere((u) => u.symbol == 'g'));
      expect(Unit.parse('kg'), Unit.weight.firstWhere((u) => u.symbol == 'kg'));
      expect(Unit.parse('gram'), Unit.weight.firstWhere((u) => u.symbol == 'g'));
      expect(Unit.parse('OZ'), Unit.weight.firstWhere((u) => u.symbol == 'oz'));
      expect(Unit.parse('pcs'), Unit.count.firstWhere((u) => u.symbol == 'pcs'));
      expect(Unit.parse('buah'), Unit.count.firstWhere((u) => u.symbol == 'pcs'));
      expect(Unit.parse('unknown'), isNull);
    });

    test('canonical unit per kind', () {
      final svc = UnitConversionService();
      expect(svc.canonicalFor(UnitKind.weight).symbol, 'g');
      expect(svc.canonicalFor(UnitKind.volume).symbol, 'ml');
      expect(svc.canonicalFor(UnitKind.length).symbol, 'cm');
      expect(svc.canonicalFor(UnitKind.count).symbol, 'pcs');
    });
  });

  group('UnitConversionService', () {
    final svc = UnitConversionService();

    test('metric weight conversions', () {
      expect(svc.convert(1, Unit.parse('kg')!, Unit.parse('g')!), 1000);
      expect(svc.convert(1000, Unit.parse('g')!, Unit.parse('kg')!), 1);
    });

    test('metric volume conversions', () {
      expect(svc.convert(1, Unit.parse('l')!, Unit.parse('ml')!), 1000);
      expect(svc.convert(250, Unit.parse('ml')!, Unit.parse('l')!), 0.25);
    });

    test('imperial weight to metric', () {
      expect(svc.convert(1, Unit.parse('oz')!, Unit.parse('g')!), closeTo(28.3495, 0.0001));
      expect(svc.convert(1, Unit.parse('lb')!, Unit.parse('g')!), closeTo(453.59237, 0.0001));
    });

    test('imperial volume to metric', () {
      expect(svc.convert(1, Unit.parse('fl oz')!, Unit.parse('ml')!), closeTo(29.5735, 0.0001));
      expect(svc.convert(1, Unit.parse('gal')!, Unit.parse('ml')!), closeTo(3785.4118, 0.0001));
    });

    test('returns null for mismatched kinds', () {
      expect(svc.convert(1, Unit.parse('g')!, Unit.parse('ml')!), isNull);
    });

    test('format produces readable string', () {
      expect(svc.format(250, Unit.parse('g')!), '250 g');
      expect(svc.format(1.5, Unit.parse('kg')!), '1.5 kg');
      expect(svc.format(1.0, Unit.parse('kg')!), '1 kg');
    });
  });

  group('HppCalculator', () {
    final calc = HppCalculator();
    final g = Unit.parse('g')!;

    test('ingredient cost converts to base unit', () {
      // ingredient price: 1 kg = Rp14,000 -> 14 / gram
      final res = calc.calculateIngredientCost(quantity: 250, unit: g, unitCost: 14);
      expect(res.totalCost, 3500);
      expect(res.unitCost, 14);
    });

    test('material cost sums ingredients', () {
      final items = [
        IngredientCostResult(quantity: 250, unit: g, unitCost: 14, totalCost: 3500),
        IngredientCostResult(quantity: 200, unit: g, unitCost: 30, totalCost: 6000),
      ];
      expect(calc.calculateMaterialCost(items), 9500);
    });

    test('additional cost sums extras', () {
      final extras = {'Gas': 2000.0, 'Kemasan': 5000.0, 'Tenaga kerja': 8000.0};
      expect(calc.calculateAdditionalCost(extras), 15000);
    });

    test('additional cost throws on negative', () {
      expect(() => calc.calculateAdditionalCost({'A': -100}), throwsArgumentError);
    });

    test('total recipe cost = material + additional', () {
      expect(calc.calculateTotalRecipeCost(materialCost: 11900, additionalCost: 15000), 26900);
    });

    test('HPP per unit = total / yield', () {
      expect(calc.calculateHppPerUnit(totalCost: 18900, yieldQuantity: 10), 1890);
    });

    test('HPP throws on zero yield', () {
      expect(() => calc.calculateHppPerUnit(totalCost: 10000, yieldQuantity: 0), throwsArgumentError);
    });

    test('margin price: HPP 10000, margin 30% -> 14285.71', () {
      final price = calc.calculateMarginPrice(hppPerUnit: 10000, margin: 0.3);
      expect(price, closeTo(14285.71, 0.01));
    });

    test('margin throws on 100% or negative', () {
      expect(() => calc.calculateMarginPrice(hppPerUnit: 10000, margin: 1), throwsArgumentError);
      expect(() => calc.calculateMarginPrice(hppPerUnit: 10000, margin: -0.1), throwsArgumentError);
    });

    test('markup price: HPP 10000, markup 30% -> 13000', () {
      expect(calc.calculateMarkupPrice(hppPerUnit: 10000, markup: 0.3), 13000);
    });

    test('markup throws on negative', () {
      expect(() => calc.calculateMarkupPrice(hppPerUnit: 10000, markup: -0.1), throwsArgumentError);
    });
  });
}
