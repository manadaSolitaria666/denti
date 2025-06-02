// lib/features/diagnosis/widgets/diagnosis_step_indicator.dart
import 'package:flutter/material.dart';

class DiagnosisStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final double stepSize;
  final double lineThickness;
  final Color activeColor;
  final Color inactiveColor;
  final List<String>? stepTitles; // Títulos opcionales para cada paso

  const DiagnosisStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepSize = 24.0,
    this.lineThickness = 2.0,
    this.activeColor = Colors.blue, // O usa Theme.of(context).colorScheme.primary
    this.inactiveColor = Colors.grey,
    this.stepTitles,
  }) : assert(stepTitles == null || stepTitles.length == totalSteps);

  @override
  Widget build(BuildContext context) {
    final Color finalActiveColor = activeColor;
    final Color finalInactiveColor = inactiveColor;

    return LayoutBuilder( // Usar LayoutBuilder para que las líneas se ajusten al espacio
      builder: (context, constraints) {
        // Calcular el ancho disponible para las líneas entre los círculos
        final double lineWidth = (constraints.maxWidth - (totalSteps * stepSize)) / (totalSteps -1 >= 1 ? totalSteps -1 : 1) ;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(totalSteps * 2 - 1, (index) {
                // Si es par, es un círculo (paso)
                if (index % 2 == 0) {
                  final stepIndex = index ~/ 2;
                  bool isActive = stepIndex <= currentStep;
                  bool isCompleted = stepIndex < currentStep;

                  return Container(
                    width: stepSize,
                    height: stepSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? finalActiveColor : finalInactiveColor.withOpacity(0.3),
                      border: Border.all(
                        color: isActive ? finalActiveColor : finalInactiveColor,
                        width: lineThickness,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, size: stepSize * 0.6, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                color: isActive ? Colors.white : finalInactiveColor,
                                fontWeight: FontWeight.bold,
                                fontSize: stepSize * 0.5,
                              ),
                            ),
                    ),
                  );
                }
                // Si es impar, es una línea
                else {
                  final lineIndex = (index -1) ~/ 2;
                  bool isActive = lineIndex < currentStep;
                  return Container(
                    width: lineWidth.isFinite && lineWidth > 0 ? lineWidth : 0, // Ancho de la línea
                    height: lineThickness,
                    color: isActive ? finalActiveColor : finalInactiveColor.withOpacity(0.5),
                  );
                }
              }),
            ),
            if (stepTitles != null) ...[
              const SizedBox(height: 8),
              Row(
                // Alinear los títulos con los círculos. Esto es aproximado.
                // Para una alineación perfecta, se necesitaría más cálculo o usar un Stack.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(totalSteps, (index) {
                  return SizedBox(
                    width: stepSize + (index < totalSteps -1 ? lineWidth : 0), // Ancho aproximado para cada título
                    child: Text(
                      stepTitles![index],
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: index <= currentStep ? finalActiveColor : finalInactiveColor,
                        fontWeight: index == currentStep ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              )
            ]
          ],
        );
      },
    );
  }
}