import 'package:intl/intl.dart';

/// Presentation-layer currency formatting only. The database always stores a
/// plain number (PRD section 10).
class Currency {
  const Currency._();

  static final idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Compact for dense lists: Rp18.900
  static String format(num value) => idr.format(value);

  /// Full precision, for values that are not whole rupiah (margin results).
  static String formatExact(num value) {
    final rounded = value.roundToDouble() == value ? value.toInt() : value;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(rounded);
  }

  static String percent(double fraction) =>
      '${NumberFormat('0.#', 'id_ID').format(fraction * 100)}%';
}
