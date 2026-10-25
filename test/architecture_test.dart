import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lee cada archivo .dart de una carpeta y devuelve qué importa (archivo -> lista de imports).
Map<String, List<String>> importsOf(String dir) { // dir = carpeta a revisar
  final result = <String, List<String>>{}; // aquí se junta el resultado
  final pattern = RegExp( // busca líneas "import '...'" o "export '...'"
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true, // una coincidencia por línea
  );
  for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) { // cada archivo de la carpeta
    if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue; // solo .dart escritos a mano
    result[f.path] = [ // los imports de este archivo
      for (final m in pattern.allMatches(f.readAsStringSync())) m.group(1)!, // la ruta entre comillas
    ];
  }
  return result; // devuelve el mapa
}

/// ¿La ruta importada pasa por alguna de esas carpetas de lib/?
bool touches(String uri, List<String> folders) => // true si toca alguna
    folders.any((f) => uri.contains('/$f/') || uri.startsWith('$f/')); // "../data/x.dart" o "package:telyser_app/data/x.dart"

/// Revisa una carpeta y falla mostrando cada import prohibido.
void expectNoForbiddenImports(String dir, bool Function(String uri) forbidden) { // forbidden = regla de qué no se puede importar
  final bad = <String>[]; // las violaciones encontradas
  importsOf(dir).forEach((file, uris) { // por cada archivo
    for (final u in uris) { // por cada import
      if (forbidden(u)) bad.add('$file importa $u'); // lo anota si está prohibido
    }
  });
  expect(bad, isEmpty, reason: bad.join('\n')); // falla y lista todas las violaciones
}

void main() {
  test('domain es Dart puro: no importa Flutter, Drift, dart:io ni capas de arriba', () { // la regla más importante
    expectNoForbiddenImports(
      'lib/domain',
      (u) =>
          u.startsWith('package:flutter') || // ni Flutter ni Riverpod
          u.startsWith('package:drift') || // ni la base de datos
          u == 'dart:io' || // ni archivos del sistema
          touches(u, ['data', 'application', 'providers', 'features', 'core']), // ni ninguna otra capa
    );
  });

  test('application no depende de pantallas, de Flutter ni de providers', () { // las acciones no conocen la interfaz
    expectNoForbiddenImports(
      'lib/application',
      (u) =>
          u.startsWith('package:flutter') || // ni Flutter
          touches(u, ['features', 'providers', 'core']), // ni pantallas, providers ni widgets
    );
  });

  test('data no depende de pantallas, providers, application ni core', () { // la base y los repositorios no conocen a quien los usa
    expectNoForbiddenImports(
      'lib/data',
      (u) => touches(u, ['features', 'providers', 'application', 'core']), // ninguna capa de arriba
    );
  });

  test('core es genérico: no conoce el negocio', () { // los widgets compartidos sirven para cualquier app
    expectNoForbiddenImports(
      'lib/core',
      (u) => touches(u, ['domain', 'data', 'application', 'providers', 'features']), // ninguna capa con reglas del negocio
    );
  });

  test('las pantallas no tocan Drift ni data directamente', () { // pasan por providers y application
    expectNoForbiddenImports(
      'lib/features',
      (u) => u.startsWith('package:drift') || touches(u, ['data']), // ni la base ni los repositorios
    );
  });
}