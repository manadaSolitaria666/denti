// lib/features/diagnosis/screens/diagnosis_form_screen.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart';
import 'package:dental_ai_app/features/auth/widgets/auth_form_field.dart'; // Reutilizamos el AuthFormField
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiagnosisFormScreen extends ConsumerStatefulWidget {
  const DiagnosisFormScreen({super.key});

  @override
  ConsumerState<DiagnosisFormScreen> createState() => _DiagnosisFormScreenState();
}

class _DiagnosisFormScreenState extends ConsumerState<DiagnosisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mainConcernController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _durationController = TextEditingController();
  // Agrega más controladores según sea necesario

  bool _hasPain = false;
  bool _hasSwelling = false;
  bool _hasBleeding = false;

  // Nodos de foco para mejorar la navegación del formulario
  final _symptomsFocusNode = FocusNode();
  final _durationFocusNode = FocusNode();


  @override
  void dispose() {
    _mainConcernController.dispose();
    _symptomsController.dispose();
    _durationController.dispose();
    _symptomsFocusNode.dispose();
    _durationFocusNode.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); 

      final formData = {
        'mainConcern': _mainConcernController.text.trim(),
        'detailedSymptoms': _symptomsController.text.trim(),
        'symptomsDuration': _durationController.text.trim(),
        'hasPain': _hasPain,
        'hasSwelling': _hasSwelling,
        'hasBleeding': _hasBleeding,
      };

      ref.read(diagnosisNotifierProvider.notifier).updateFormData(formData);
      context.goNamed(AppRoutes.imageCaptureGuide);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Paciente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Considerar preguntar al usuario si desea descartar los cambios
            // o limpiar el estado del diagnóstico si es necesario.
            // Por ejemplo, mostrando un showDialog.
            // ref.read(diagnosisNotifierProvider.notifier).resetDiagnosisFlow(); // O una limpieza más selectiva
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Describe tu Situación Dental',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta información ayudará a la IA a entender mejor tu caso.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AuthFormField(
                controller: _mainConcernController,
                labelText: 'Motivo Principal de Consulta',
                hintText: 'Ej: Dolor en una muela, revisión general',
                maxLines: 2, // Ahora AuthFormField soporta maxLines
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                onFieldSubmitted: (_) { // Navegar al siguiente campo
                  FocusScope.of(context).requestFocus(_symptomsFocusNode);
                },
              ),
              AuthFormField(
                controller: _symptomsController,
                focusNode: _symptomsFocusNode,
                labelText: 'Síntomas Detallados',
                hintText: 'Ej: Dolor agudo al masticar, sensibilidad al frío/calor, encías rojas...',
                maxLines: 4, // Ahora AuthFormField soporta maxLines
                textInputAction: TextInputAction.next, // Cambiado de next a newline para campos multilínea
                                                      // o mantener next si se prefiere saltar con el botón del teclado
                keyboardType: TextInputType.multiline, // Asegurar que el tipo de teclado sea multilínea
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                onFieldSubmitted: (_) {
                   FocusScope.of(context).requestFocus(_durationFocusNode);
                }
              ),
              AuthFormField(
                controller: _durationController,
                focusNode: _durationFocusNode,
                labelText: '¿Desde cuándo tienes estos síntomas?',
                hintText: 'Ej: 3 días, 2 semanas, varios meses',
                textInputAction: TextInputAction.done, // Último campo de texto antes de los checkboxes
                 validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                onFieldSubmitted: (_) => _submitForm(), // Opcional: intentar enviar al presionar done
              ),
              const SizedBox(height: 20),
              Text('Selecciona si presentas alguno de los siguientes:', style: Theme.of(context).textTheme.titleMedium),
              CheckboxListTile(
                title: const Text('Dolor'),
                value: _hasPain,
                onChanged: (bool? value) {
                  setState(() {
                    _hasPain = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Inflamación / Hinchazón'),
                value: _hasSwelling,
                onChanged: (bool? value) {
                  setState(() {
                    _hasSwelling = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                 contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Sangrado de Encías (al cepillar o espontáneo)'),
                value: _hasBleeding,
                onChanged: (bool? value) {
                  setState(() {
                    _hasBleeding = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                 contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                label: const Text('Siguiente: Tomar Fotos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
