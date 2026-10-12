import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telyser_app/app.dart';

void main() {
  testWidgets('sin sesión se muestra el login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TelyserApp()));

    expect(find.text('TELYSER'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}