import 'package:flutter_test/flutter_test.dart'; // herramientas de prueba
import 'package:telyser_app/domain/format.dart'; // lo que se prueba

void main() {
  test('los enteros no llevan decimales', () { // 5.0 -> "5"
    expect(formatNumber(5.0), '5'); // decimal entero
    expect(formatNumber(120), '120'); // entero
    expect(formatNumber(0), '0'); // cero
  });

  test('los decimales no llevan ceros sobrantes', () { // 12.40 -> "12.4"
    expect(formatNumber(12.4), '12.4'); // un decimal
    expect(formatNumber(2.25), '2.25'); // dos decimales
    expect(formatNumber(100.5), '100.5'); // no se come el cero de 100
  });

  test('se redondea al máximo de decimales', () { // para kilómetros
    expect(formatNumber(12.43, decimals: 1), '12.4'); // un decimal
    expect(formatNumber(10.001), '10'); // redondea a entero sin dejar "10."
  });
}