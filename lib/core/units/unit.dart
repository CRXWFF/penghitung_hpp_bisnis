/// Unit dimension. Database always stores canonical values
/// (weight=gram, volume=milliliter, length=centimeter), so switching the
/// display unit system never changes stored data or HPP math.
enum UnitKind { weight, volume, length, count }

/// A unit of measure plus its conversion factor to the canonical unit of its
/// [kind]: gram, milliliter, centimeter, or piece.
class Unit {
  const Unit(this.symbol, this.kind, this.toCanonical, {this.aliases = const []});

  final String symbol;
  final UnitKind kind;

  /// How many canonical units (gram/ml/cm/piece) one [symbol] equals.
  final double toCanonical;

  /// Extra symbols treated as the same unit when parsing user input.
  final List<String> aliases;

  static const weight = <Unit>[
    Unit('g', UnitKind.weight, 1, aliases: ['gram', 'grama']),
    Unit('kg', UnitKind.weight, 1000, aliases: ['kilo', 'kilogram']),
    Unit('oz', UnitKind.weight, 28.349523125, aliases: ['ounce']),
    Unit('lb', UnitKind.weight, 453.59237, aliases: ['pound']),
  ];

  static const volume = <Unit>[
    Unit('ml', UnitKind.volume, 1, aliases: ['milliliter', 'cc']),
    Unit('l', UnitKind.volume, 1000, aliases: ['liter', 'ltr']),
    Unit('fl oz', UnitKind.volume, 29.5735295625, aliases: ['fl_oz', 'fluid ounce']),
    Unit('gal', UnitKind.volume, 3785.411784, aliases: ['gallon']),
  ];

  static const length = <Unit>[
    Unit('cm', UnitKind.length, 1, aliases: ['sentimeter']),
    Unit('m', UnitKind.length, 100, aliases: ['meter']),
    Unit('in', UnitKind.length, 2.54, aliases: ['inch']),
    Unit('ft', UnitKind.length, 30.48, aliases: ['feet', 'foot']),
  ];

  static const count = <Unit>[
    Unit('pcs', UnitKind.count, 1, aliases: ['pc', 'buah', 'biji', 'porsi']),
  ];

  static const all = <Unit>[...weight, ...volume, ...length, ...count];

  /// Units offered in the UI for [kind]. Metric is the base list; imperial
  /// appends the imperial-only units (metric stays available either way).
  static List<Unit> forSystem(UnitKind kind, {required bool imperial}) {
    final base = switch (kind) {
      UnitKind.weight => weight,
      UnitKind.volume => volume,
      UnitKind.length => length,
      UnitKind.count => count,
    };
    if (!imperial) return base;
    return [...base, ...(imperialOnly[kind] ?? const <Unit>[])];
  }

  static const imperialOnly = <UnitKind, List<Unit>>{
    UnitKind.weight: [Unit('oz', UnitKind.weight, 28.349523125), Unit('lb', UnitKind.weight, 453.59237)],
    UnitKind.volume: [Unit('fl oz', UnitKind.volume, 29.5735295625), Unit('gal', UnitKind.volume, 3785.411784)],
    UnitKind.length: [Unit('in', UnitKind.length, 2.54), Unit('ft', UnitKind.length, 30.48)],
  };

  /// Resolve a user-entered unit string. Returns null when unknown.
  static Unit? parse(String raw) {
    final key = raw.trim().toLowerCase().replaceAll('.', '');
    if (key.isEmpty) return null;
    for (final u in all) {
      if (u.symbol.toLowerCase() == key || u.aliases.contains(key)) return u;
    }
    return null;
  }

  static Unit get defaultForMetric => count.first;

  /// Human label for a kind, e.g. "Berat".
  static String kindLabel(UnitKind kind) => switch (kind) {
        UnitKind.weight => 'Berat',
        UnitKind.volume => 'Volume',
        UnitKind.length => 'Panjang',
        UnitKind.count => 'Jumlah',
      };
}

/// Metric <-> imperial display option from Settings.
enum UnitSystem { metric, imperial }
