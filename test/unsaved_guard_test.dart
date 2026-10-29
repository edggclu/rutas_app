import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/core/widgets/unsaved_guard.dart';

/// Una pantalla de ejemplo con un botón "Atrás" que usa maybePop, como el encabezado de la app.
Widget _app({required bool dirty, Future<void> Function()? onDiscard}) => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => UnsavedGuard(
                dirty: dirty,
                onDiscard: onDiscard,
                child: Scaffold(
                  body: Builder(
                    builder: (inner) => TextButton(
                      onPressed: () => Navigator.of(inner).maybePop(),
                      child: const Text('Atrás'),
                    ),
                  ),
                ),
              ),
            )),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('sin cambios, atrás sale sin preguntar', (tester) async {
    await tester.pumpWidget(_app(dirty: false));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget); // volvió
    expect(find.text('¿Salir sin guardar?'), findsNothing);
  });

  testWidgets('con cambios, atrás pregunta y "Seguir editando" se queda', (tester) async {
    await tester.pumpWidget(_app(dirty: true));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir sin guardar?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Atrás'), findsOneWidget); // sigue en la pantalla
  });

  testWidgets('con cambios, "Salir sin guardar" sale y limpia', (tester) async {
    var cleaned = false;
    await tester.pumpWidget(_app(dirty: true, onDiscard: () async => cleaned = true));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atrás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir sin guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget); // volvió
    expect(cleaned, isTrue);
  });
}
