// lib/features/diagnosis/widgets/captured_image_thumbnail.dart
import 'dart:io';
import 'package:flutter/material.dart';

class CapturedImageThumbnail extends StatelessWidget {
  final File imageFile;
  final String angleTitle;
  final VoidCallback? onRetake; // Para volver a tomar la foto
  final VoidCallback? onView;   // Para ver la foto en grande (opcional)

  const CapturedImageThumbnail({
    super.key,
    required this.imageFile,
    required this.angleTitle,
    this.onRetake,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              angleTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetake != null)
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Retomar', style: TextStyle(fontSize: 12)),
              onPressed: onRetake,
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            ),
        ],
      ),
    );
  }
}
