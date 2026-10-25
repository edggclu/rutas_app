import 'package:flutter/services.dart';

/// Filtros para los campos de texto. El tipo de teclado solo sugiere qué mostrar:
/// no impide pegar letras ni escribir con un teclado externo, estos filtros sí.

/// Cantidades: solo dígitos y un punto o coma decimal, hasta 2 decimales y 8 caracteres.
final List<TextInputFormatter> decimalInput = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
  LengthLimitingTextInputFormatter(8),
];

/// Enteros (por ejemplo, minutos o piezas): solo dígitos, hasta 4.
final List<TextInputFormatter> integerInput = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(4),
];

/// Texto de una sola línea con largo máximo (nombres, etiquetas, seriales).
List<TextInputFormatter> shortText([int max = 80]) => [LengthLimitingTextInputFormatter(max)];
