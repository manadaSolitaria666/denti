// lib/widgets/loading_spinner.dart
import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message; // Mensaje opcional debajo del spinner

  const LoadingSpinner({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: effectiveColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}