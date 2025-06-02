// test/widget_test.dart

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importar ProviderScope
import 'package:flutter_test/flutter_test.dart';

// Importa el archivo que define tu widget principal (DentalAiApp).
// Puede ser 'app.dart' o 'main.dart' si main.dart exporta o instancia DentalAiApp.
// Asumiremos que main.dart es el punto de entrada y es suficiente,
// o puedes importar 'package:dental_ai_app/app.dart'; directamente.
import 'package:dental_ai_app/app.dart'; // Importando app.dart donde está DentalAiApp
// O si prefieres y es más simple, puedes importar main.dart y asegurarte
// que expone lo necesario o que la prueba llama a main() de alguna forma.
// Pero para pumpWidget, necesitas el widget directamente.

void main() {
  testWidgets('Smoke test: App loads initial screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Envuelve DentalAiApp con ProviderScope, igual que en main.dart
    await tester.pumpWidget(
      const ProviderScope(
        child: DentalAiApp(), // CORRECCIÓN: Usa tu widget raíz DentalAiApp
      ),
    );

    // Ejemplo: Verificar que el título 'Dental AI' o un elemento inicial esté presente.
    // Esta prueba es muy básica y dependerá de tu UI inicial en estado de carga/login.
    // Por ejemplo, si la primera pantalla visible (después de splash) es LoginScreen
    // y esta tiene un texto 'Bienvenido de Nuevo', podrías buscarlo.

    // Como la app tiene un flujo de autenticación y splash, la prueba inicial
    // podría ser más compleja. Por ahora, solo verificamos que no crashee al inicio.
    // expect(find.text('Dental AI'), findsOneWidget); // Esto buscaría en el título de MaterialApp

    // Ejemplo de prueba más específica si la app fuera más simple:
    // Verify that our counter starts at 0.
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);
  });
}
