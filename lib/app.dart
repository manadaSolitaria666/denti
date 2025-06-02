
// lib/app.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DentalAiApp extends ConsumerWidget {
  const DentalAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider); // Observa el router desde Riverpod

    return MaterialApp.router(
      title: 'Dental AI',
      theme: AppTheme.lightTheme, // Define tu tema claro
      darkTheme: AppTheme.darkTheme, // Opcionalmente, define un tema oscuro
      themeMode: ThemeMode.light, // O el que prefieras -----------system, para elegir segun el usuario
      routerConfig: goRouter, // Usa la configuración de GoRouter
      debugShowCheckedModeBanner: false,
    );
  }
}