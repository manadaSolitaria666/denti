// lib/features/diagnosis_history/widgets/diagnosis_report_card.dart (Corregido)
import 'package:dental_ai_app/core/models/diagnosis_report_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiagnosisReportCard extends StatelessWidget {
  final DiagnosisReportModel report;
  final VoidCallback onTap;

  const DiagnosisReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  // Widget helper para mostrar la severidad con un color distintivo
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
      avatar: Icon(iconData, color: Colors.white, size: 16),
      label: Text(
        severity.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final String formattedDate = dateFormat.format(report.createdAt.toDate());

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
                  // Usa el nivel de severidad para el título/estado
                  _buildSeverityChip(context, report.severityLevel),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                'Resumen del Análisis:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              // Usa el nuevo campo 'overallSummary'
              Text(
                report.overallSummary,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver Detalles Completos →',
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
