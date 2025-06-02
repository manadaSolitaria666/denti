// lib/features/diagnosis/widgets/photo_guideline_widget.dart
import 'package:flutter/material.dart';

class PhotoGuideline {
  final String title;
  final String instruction;
  final IconData icon; // Icono representativo del ángulo

  const PhotoGuideline({
    required this.title,
    required this.instruction,
    required this.icon,
  });
}

class PhotoGuidelineWidget extends StatelessWidget {
  final PhotoGuideline guideline;

  const PhotoGuidelineWidget({super.key, required this.guideline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(guideline.icon, size: 28.0, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  guideline.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guideline.instruction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

