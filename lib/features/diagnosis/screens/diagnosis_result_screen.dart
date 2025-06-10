// lib/features/diagnosis/screens/diagnosis_result_screen.dart
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart';
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:dental_ai_app/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';

final specificReportProvider = FutureProvider.autoDispose.family<DiagnosisReportModel?, String>((ref, reportId) async {
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  if (userId == null) return null;

  final firestoreService = ref.watch(firestoreServiceProvider);
  try {
    final docSnapshot = await firestoreService.reportsCollection(userId).doc(reportId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  } catch (e) {
    return null;
  }
});


class DiagnosisResultScreen extends ConsumerWidget {
  final String reportId;
  final bool isFromHistory;

  const DiagnosisResultScreen({
    super.key,
    required this.reportId,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsyncValue = ref.watch(specificReportProvider(reportId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del Análisis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isFromHistory) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.home);
              Future.microtask(() => ref.read(diagnosisNotifierProvider.notifier).resetDiagnosisFlow());
            }
          },
        ),
      ),
      body: reportAsyncValue.when(
        data: (report) {
          if (report == null) {
            return const Center(child: Text('No se pudo cargar el reporte.'));
          }
          if (report.error != null) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error en el análisis: ${report.error}')));
          }
          return _buildReportDetails(context, report, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al cargar el reporte: $err', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(BuildContext context, String severity) {
    Color chipColor;
    IconData iconData;

    switch (severity.toLowerCase()) {
      case 'urgente':
        chipColor = Colors.red.shade700;
        iconData = Icons.error_outline;
        break;
      case 'alto':
        chipColor = Colors.orange.shade700;
        iconData = Icons.warning_amber_rounded;
        break;
      case 'moderado':
        chipColor = Colors.amber.shade700;
        iconData = Icons.info_outline;
        break;
      case 'bajo':
        chipColor = Colors.green.shade700;
        iconData = Icons.check_circle_outline;
        break;
      default:
        chipColor = Colors.grey.shade700;
        iconData = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 20),
      label: Text(severity.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }


  Widget _buildReportDetails(BuildContext context, DiagnosisReportModel report, WidgetRef ref) {
    
    return SafeArea(
      left: false, right: false, top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: <Widget>[
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Resumen del Análisis',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildSeverityChip(context, report.severityLevel),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  Text(report.overallSummary, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          
          if (report.possibleConditions.isNotEmpty) ...[
            _buildSectionTitle(context, 'Posibles Condiciones', Icons.healing_outlined),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: report.possibleConditions.map((condition) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Icon(Icons.arrow_right, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(condition, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
          
           _buildSectionTitle(context, 'Recomendaciones Detalladas', Icons.recommend_outlined),
           const SizedBox(height: 8),
           Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(report.detailedRecommendations, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
            ),
          
          _buildSectionTitle(context, 'Próximos Pasos', Icons.directions_walk_outlined),
          const SizedBox(height: 8),
          Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(report.nextSteps, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer), textAlign: TextAlign.center),
              ),
            ),
          const SizedBox(height: 24),

          if (report.images.isNotEmpty) ...[
            _buildSectionTitle(context, 'Imágenes de Referencia', Icons.photo_library_outlined),
            const SizedBox(height: 8),
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                enableInfiniteScroll: report.images.length > 1,
                viewportFraction: 0.7,
              ),
              items: report.images.map((imageModel) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Theme.of(context).dividerColor)
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageModel.downloadUrl != null && imageModel.downloadUrl!.isNotEmpty
                            ? Image.network(
                                imageModel.downloadUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Icon(Icons.broken_image, size: 50));
                                },
                              )
                            : const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buscar Consultorios Cercanos'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
            onPressed: () => context.goNamed(AppRoutes.nearbyClinicsMap),
          ),
          if (!isFromHistory) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al Inicio'),
               style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14.0)),
              onPressed: () {
                context.goNamed(AppRoutes.home);
                ref.read(diagnosisNotifierProvider.notifier).resetDiagnosisFlow();
              },
            ),
          ]
        ],
      ),
    );
  }
}
