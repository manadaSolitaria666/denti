// lib/features/home/screens/home_screen.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/auth_provider.dart';
import 'package:dental_ai_app/core/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dental AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              // GoRouter se encargará de la redirección a Login
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              userProfileAsyncValue.when(
                data: (user) {
                  if (user != null && user.name != null) {
                    return Text(
                      '¡Hola, ${user.name}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    );
                  }
                  return Text(
                    'Bienvenido/a',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  );
                },
                loading: () => const SizedBox(height: 28), // Placeholder para mantener altura
                error: (err, stack) => Text(
                  'Bienvenido/a',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Listo para tu análisis dental IA?',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Placeholder para una imagen o ilustración
              Icon(
                Icons.camera_alt_outlined, // O una imagen más representativa
                size: 100,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Generar Nuevo Diagnóstico'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  // Navegar a la pantalla de formulario de diagnóstico
                  context.goNamed(AppRoutes.diagnosisForm);
                },
              ),
              const SizedBox(height: 20),
              // Podrías añadir aquí accesos rápidos a otras secciones si quieres
              // TextButton(
              //   onPressed: () => context.goNamed(AppRoutes.diagnosisHistory),
              //   child: const Text('Ver Historial de Diagnósticos'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
