import 'package:flutter/services.dart'; // TextEditingValue
import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/core/widgets/input_formatters.dart'; // lo que se prueba

/// Lo que queda en el campo después de pegar [text] en un campo vacío.
String _paste(List<TextInputFormatter> formatters, String text) {
  var value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  for (final f in formatters) {
    value = f.formatEditUpdate(TextEditingValue.empty, value); // la salida de uno entra al siguiente
  }
  return value.text;
}

void main() {
  test('las cantidades descartan letras y signos', () {
    expect(_paste(decimalInput, 'abc'), '');
    expect(_paste(decimalInput, '-5'), '');
    expect(_paste(decimalInput, '1e3'), '1'); // se queda con lo válido y descarta el resto
  });

  test('las cantidades aceptan enteros y hasta 2 decimales con punto o coma', () {
    expect(_paste(decimalInput, '12'), '12');
    expect(_paste(decimalInput, '2.5'), '2.5');
    expect(_paste(decimalInput, '2,25'), '2,25');
    expect(_paste(decimalInput, '1.234'), '1.23'); // el tercer decimal se descarta
  });

  test('los enteros solo aceptan dígitos y hasta 4', () {
    expect(_paste(integerInput, '12a'), '12');
    expect(_paste(integerInput, '1.5'), '15');
    expect(_paste(integerInput, '123456'), '1234');
  });

  test('el texto corto respeta su largo máximo', () {
    expect(_paste(shortText(5), 'abcdefgh'), 'abcde');
  });
}
