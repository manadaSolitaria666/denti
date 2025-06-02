// lib/features/diagnosis_history/widgets/diagnosis_report_card.dart
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class DiagnosisReportCard extends StatelessWidget {
  final DiagnosisReportModel report;
  final VoidCallback onTap;

  const DiagnosisReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final String formattedDate = dateFormat.format(report.createdAt.toDate());

    // Mostrar un resumen de los signos o un placeholder
    String signsSummary = report.identifiedSigns.isNotEmpty
        ? report.identifiedSigns
        : "No se identificaron signos específicos.";
    if (signsSummary.length > 100) {
      signsSummary = "${signsSummary.substring(0, 97)}...";
    }

    // Determinar el color del ícono basado en si hubo un error en el reporte
    IconData statusIcon = Icons.check_circle_outline;
    Color statusColor = Colors.green.shade700;

    if (report.error != null && report.error!.isNotEmpty) {
      statusIcon = Icons.error_outline;
      statusColor = Colors.red.shade700;
    } else if (report.identifiedSigns.toLowerCase().contains("visitar") ||
               report.recommendations.toLowerCase().contains("visitar") ||
               report.identifiedSigns.toLowerCase().contains("dentista") ||
               report.recommendations.toLowerCase().contains("dentista") ||
               report.identifiedSigns.toLowerCase().contains("urgente") ||
               report.recommendations.toLowerCase().contains("urgente")) {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.orange.shade800;
    }


    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reporte: ${report.id.substring(0, 6)}...', // ID corto
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                   Icon(statusIcon, color: statusColor, size: 28),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Fecha: $formattedDate',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 16),
              Text(
                'Signos principales:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                signsSummary,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver Detalles →',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
