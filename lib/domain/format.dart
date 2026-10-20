/// Muestra un número sin ceros sobrantes: 5.0 -> "5", 12.4 -> "12.4", 2.25 -> "2.25".
String formatNumber(num value, {int decimals = 2}) { // decimals = máximo de decimales a mostrar
  if (value % 1 == 0) return value.toInt().toString(); // si es entero, sin punto decimal
  final fixed = value.toStringAsFixed(decimals); // redondea, ej. "12.40"
  if (!fixed.contains('.')) return fixed; // sin decimales que limpiar
  return fixed.replaceFirst(RegExp(r'\.?0+$'), ''); // quita los ceros finales (y el punto si queda solo)
}