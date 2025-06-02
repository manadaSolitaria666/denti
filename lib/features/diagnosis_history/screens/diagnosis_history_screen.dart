// lib/features/diagnosis_history/screens/diagnosis_history_screen.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart'; // Para el stream diagnosisHistoryProvider
import 'package:dental_ai_app/features/diagnosis_history/widgets/diagnosis_report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiagnosisHistoryScreen extends ConsumerWidget {
  const DiagnosisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsyncValue = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Diagnósticos'),
        // No necesitamos botón de atrás si es parte del ShellRoute,
        // pero si se accede de otra forma, GoRouter lo manejará.
      ),
      body: historyAsyncValue.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay diagnósticos aún.',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Genera un nuevo análisis para verlo aquí.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Generar Diagnóstico'),
                      onPressed: () => context.goNamed(AppRoutes.diagnosisForm),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return DiagnosisReportCard(
                report: report,
                onTap: () {
                  context.goNamed(
                    AppRoutes.diagnosisDetail, // Ruta anidada de diagnosisHistory
                    pathParameters: {'reportId': report.id},
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          // print("Error en DiagnosisHistoryScreen: $err");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar el historial: ${err.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }
}