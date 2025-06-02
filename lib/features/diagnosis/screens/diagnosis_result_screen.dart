// lib/features/diagnosis/screens/diagnosis_result_screen.dart
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart'; 
import 'package:dental_ai_app/core/services/auth_service.dart'; // Para authStateChangesProvider
import 'package:dental_ai_app/core/services/firestore_service.dart'; // Para firestoreServiceProvider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; 
import 'package:carousel_slider/carousel_slider.dart'; 

// Provider para cargar un reporte específico por ID.
// Usamos .family para pasar el reportId.
final specificReportProvider = FutureProvider.autoDispose.family<DiagnosisReportModel?, String>((ref, reportId) async {
  final userId = ref.watch(authStateChangesProvider).value?.uid;
  if (userId == null) {
    // print("specificReportProvider: Usuario no autenticado.");
    return null;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  try {
    // CORRECCIÓN AQUÍ: Usar el reportId pasado como argumento
    final docSnapshot = await firestoreService.reportsCollection(userId).doc(reportId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data(); // El método .data() ya usa el converter
    } else {
      // print("specificReportProvider: Reporte con ID $reportId no encontrado para el usuario $userId.");
      return null; // Reporte no encontrado
    }
  } catch (e) {
    // print("Error cargando reporte específico (ID: $reportId): $e");
    return null; // Devolver null en caso de error
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No se pudo cargar el reporte.', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text("ID del Reporte: $reportId", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            );
          }
          return _buildReportDetails(context, report, ref); // Pasar ref para limpiar estado
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

  Widget _buildReportDetails(BuildContext context, DiagnosisReportModel report, WidgetRef ref) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy, HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporte de Análisis Dental IA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Fecha: ${dateFormat.format(report.createdAt.toDate())}'),
                const Divider(height: 24, thickness: 1),
                _buildSectionTitle(context, 'Información Proporcionada:', Icons.list_alt_outlined),
                ...report.formData.entries.map((entry) {
                  if (entry.key.startsWith('image_angle_description_')) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('${_formatFormKey(entry.key)}: ${entry.value.toString()}'),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (report.images.isNotEmpty) ...[
          _buildSectionTitle(context, 'Imágenes Capturadas:', Icons.photo_library_outlined),
          const SizedBox(height: 8),
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              enlargeCenterPage: true,
              enableInfiniteScroll: report.images.length > 1,
              viewportFraction: 0.7,
              aspectRatio: 16/9,
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
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Análisis IA (Gemini):', Icons.auto_awesome_outlined),
                const SizedBox(height: 8),
                Text(
                  'Signos Identificados:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report.identifiedSigns.isNotEmpty ? report.identifiedSigns : "No se identificaron signos específicos."),
                const SizedBox(height: 12),
                Text(
                  'Recomendaciones:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report.recommendations.isNotEmpty ? report.recommendations : "No se generaron recomendaciones específicas."),
                 if (report.error != null && report.error!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Error en el Análisis:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(report.error!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Importante: Este análisis es una herramienta preliminar y no reemplaza la consulta con un profesional dental calificado. Te recomendamos visitar a tu dentista para una evaluación completa y un diagnóstico definitivo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.map_outlined),
          label: const Text('Buscar Consultorios Cercanos'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () {
            context.goNamed(AppRoutes.nearbyClinicsMap);
          },
        ),
        if (!isFromHistory) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.home_outlined),
            label: const Text('Volver al Inicio'),
             style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              textStyle: Theme.of(context).textTheme.titleMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              context.goNamed(AppRoutes.home);
              // Limpiar el estado del flujo de diagnóstico actual.
              // Es importante llamar a resetDiagnosisFlow para que un nuevo diagnóstico
              // no herede datos del anterior.
              ref.read(diagnosisNotifierProvider.notifier).resetDiagnosisFlow();
            },
          ),
        ]
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatFormKey(String key) {
    if (key == 'mainConcern') return 'Motivo Principal';
    if (key == 'detailedSymptoms') return 'Síntomas Detallados';
    if (key == 'symptomsDuration') return 'Duración de Síntomas';
    if (key == 'hasPain') return 'Presenta Dolor';
    if (key == 'hasSwelling') return 'Presenta Inflamación';
    if (key == 'hasBleeding') return 'Presenta Sangrado';
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
              .replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase());
  }
}
