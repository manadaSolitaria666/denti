// lib/main.dart
import 'package:dental_ai_app/app.dart';
// Asegúrate de que la ruta a firebase_options.dart sea correcta.
// Si está en lib/, debería ser: import 'firebase_options.dart';
// Si está en lib/core/services/, entonces la que tienes está bien.
import 'package:dental_ai_app/core/services/firebase_options.dart'; // Asegúrate de generar este archivo con FlutterFire CLI
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // <<<--- AÑADE ESTA IMPORTACIÓN
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_ai_app/core/utils/notification_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Usa el archivo generado por FlutterFire
  );

  // Inicializar Firebase App Check <<<--- AÑADE ESTA SECCIÓN
  try {
    await FirebaseAppCheck.instance.activate(
      // Para desarrollo, usa AndroidProvider.debug.
      // Para producción, CAMBIA a AndroidProvider.playIntegrity y asegúrate de
      // haber configurado las huellas SHA de tu app en Firebase Console.
      androidProvider: AndroidProvider.debug, 
      
      // Si también desarrollas para iOS y quieres App Check:
      // appleProvider: AppleProvider.debug, // Para desarrollo en iOS
      // O para producción en iOS:
      // appleProvider: AppleProvider.appAttest, // o AppleProvider.deviceCheck si App Attest no está disponible
    );
    print('Firebase App Check activated successfully.');
  } catch (e) {
    print('Error activating Firebase App Check: $e');
    // Considera cómo manejar este error. ¿La app puede continuar sin App Check?
    // Para desarrollo, podría ser aceptable. Para producción, es un problema de seguridad.
  }

  // Inicializar notificaciones (opcional, si quieres configurar canales al inicio)
  await NotificationUtil.initialize();


  runApp(
    const ProviderScope( // ProviderScope es necesario para Riverpod
      child: DentalAiApp(),
    ),
  );
}
