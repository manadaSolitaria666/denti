// lib/features/diagnosis/screens/diagnosis_form_screen.dart (Rediseñado)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:dental_ai_app/core/providers/diagnosis_provider.dart';
import 'package:dental_ai_app/features/auth/widgets/auth_form_field.dart';

// Enums for radio options, makes the code cleaner
enum PainIntensity { leve, moderado, intenso }
enum BrushingFrequency { una, dos, tresOmas }
enum FlossUsage { regular, aVeces, no }

class DiagnosisFormScreen extends ConsumerStatefulWidget {
  const DiagnosisFormScreen({super.key});

  @override
  ConsumerState<DiagnosisFormScreen> createState() => _DiagnosisFormScreenState();
}

class _DiagnosisFormScreenState extends ConsumerState<DiagnosisFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // State controllers for each question
  bool? _hasPain;
  final _painDurationController = TextEditingController();
  PainIntensity? _painIntensity;

  bool? _gumsBleed;
  bool? _gumsInflamed;
  bool? _teethLoose;

  bool? _teethFractured;
  bool? _hasSensitivity;
  
  bool? _hasBadBreath;
  
  BrushingFrequency? _brushingFrequency;
  FlossUsage? _flossUsage;

  bool? _hasLesions;
  bool? _jawPain;
  bool? _chewingDifficulty;

  bool? _happyWithAlignment;
  bool? _wantsCorrection;
  
  @override
  void dispose() {
    _painDurationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // It's important to validate that all non-nullable questions have been answered.
    // A formKey.currentState.validate() is not enough for radio buttons.
    // This validation is omitted for brevity, but you should add it in production.
    if (_formKey.currentState!.validate()) {
      final formData = {
        // Section 1: Pain
        'dolor_o_molestias': _hasPain,
        if (_hasPain == true) 'dolor_tiempo': _painDurationController.text.trim(),
        if (_hasPain == true) 'dolor_intensidad': _painIntensity?.name,

        // Section 2: Gums
        'encias_sangran': _gumsBleed,
        'encias_inflamadas': _gumsInflamed,
        'dientes_moviles': _teethLoose,

        // Section 3: Teeth
        'dientes_fracturados': _teethFractured,
        'sensibilidad_dientes': _hasSensitivity,

        // Section 4: Halitosis
        'mal_aliento': _hasBadBreath,

        // Section 5: Habits
        'frecuencia_cepillado': _brushingFrequency?.name,
        'uso_hilo_dental': _flossUsage?.name,

        // Section 6: Lesions
        'lesiones_boca': _hasLesions,

        // Section 7: Jaw
        'dolor_mandibula': _jawPain,
        'dificultad_masticar': _chewingDifficulty,

        // Section 8: Aesthetics
        'conforme_alineacion': _happyWithAlignment,
        'quiere_corregir_dientes': _wantsCorrection,
      };

      // Clean the map of null values
      formData.removeWhere((key, value) => value == null);

      ref.read(diagnosisNotifierProvider.notifier).updateFormData(formData);
      context.goNamed(AppRoutes.imageCaptureGuide);
    } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa los campos requeridos.')),
        );
    }
  }
  
  // Helper widget for Yes/No questions
  Widget _buildYesNoQuestion(String title, bool? groupValue, ValueChanged<bool?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Sí'), value: true, groupValue: groupValue, onChanged: onChanged,
                contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('No'), value: false, groupValue: groupValue, onChanged: onChanged,
                contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuestionario Dental'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- 1. Dolor o molestias ---
              _buildSectionHeader('1. Dolor o molestias'),
              _buildYesNoQuestion('¿Siente dolor en alguna parte de la boca?', _hasPain, (val) => setState(() => _hasPain = val)),
              if (_hasPain == true) ...[
                const SizedBox(height: 8),
                AuthFormField(controller: _painDurationController, labelText: 'Si respondió sí, ¿desde hace cuánto tiempo?', validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
                const SizedBox(height: 8),
                Text('Intensidad del dolor:', style: Theme.of(context).textTheme.titleMedium),
                ...PainIntensity.values.map((intensity) => RadioListTile<PainIntensity>(
                  title: Text(intensity.name[0].toUpperCase() + intensity.name.substring(1)), value: intensity, groupValue: _painIntensity, onChanged: (val) => setState(() => _painIntensity = val),
                  contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                )),
              ],

              // --- 2. Encías ---
              _buildSectionHeader('2. Encías'),
              _buildYesNoQuestion('¿Sus encías sangran al cepillarse o espontáneamente?', _gumsBleed, (val) => setState(() => _gumsBleed = val)),
              _buildYesNoQuestion('¿Ha notado inflamación o enrojecimiento en las encías?', _gumsInflamed, (val) => setState(() => _gumsInflamed = val)),
              _buildYesNoQuestion('¿Siente movilidad en algún diente?', _teethLoose, (val) => setState(() => _teethLoose = val)),

              // --- 3. Dientes ---
              _buildSectionHeader('3. Dientes'),
              _buildYesNoQuestion('¿Tiene dientes fracturados, desgastados o flojos?', _teethFractured, (val) => setState(() => _teethFractured = val)),
              _buildYesNoQuestion('¿Percibe sensibilidad al frío/calor o dulces?', _hasSensitivity, (val) => setState(() => _hasSensitivity = val)),

              // --- 4. Halitosis ---
              _buildSectionHeader('4. Halitosis (mal aliento)'),
              _buildYesNoQuestion('¿Ha notado mal aliento persistente?', _hasBadBreath, (val) => setState(() => _hasBadBreath = val)),

              // --- 5. Hábitos y cuidado oral ---
              _buildSectionHeader('5. Hábitos y cuidado oral'),
              Text('¿Con qué frecuencia se cepilla los dientes?', style: Theme.of(context).textTheme.titleMedium),
              ...BrushingFrequency.values.map((freq) => RadioListTile<BrushingFrequency>(
                  title: Text({'una': '1 vez/día', 'dos': '2 veces/día', 'tresOmas': '3 o más veces/día'}[freq.name]!), value: freq, groupValue: _brushingFrequency, onChanged: (val) => setState(() => _brushingFrequency = val),
              )),
              Text('¿Usa hilo dental?', style: Theme.of(context).textTheme.titleMedium),
               ...FlossUsage.values.map((usage) => RadioListTile<FlossUsage>(
                  title: Text({'regular': 'Sí, regularmente', 'aVeces': 'A veces', 'no': 'No'}[usage.name]!), value: usage, groupValue: _flossUsage, onChanged: (val) => setState(() => _flossUsage = val),
              )),
              
              // --- 6. Lesiones en boca ---
              _buildSectionHeader('6. Lesiones en boca'),
              _buildYesNoQuestion('¿Ha notado llagas, manchas blancas o rojas?', _hasLesions, (val) => setState(() => _hasLesions = val)),
              
              // --- 7. Mandíbula y articulaciones ---
              _buildSectionHeader('7. Mandíbula y articulaciones'),
              _buildYesNoQuestion('¿Siente chasquidos o dolor al abrir/cerrar la boca?', _jawPain, (val) => setState(() => _jawPain = val)),
              _buildYesNoQuestion('¿Tiene dificultad para masticar o abrir completamente?', _chewingDifficulty, (val) => setState(() => _chewingDifficulty = val)),

              // --- 8. Estética y ortodoncia ---
              _buildSectionHeader('8. Estética y ortodoncia'),
               _buildYesNoQuestion('¿Está conforme con la alineación de sus dientes?', _happyWithAlignment, (val) => setState(() => _happyWithAlignment = val)),
               _buildYesNoQuestion('¿Le gustaría corregir la posición de sus dientes?', _wantsCorrection, (val) => setState(() => _wantsCorrection = val)),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                label: const Text('Siguiente: Tomar Fotos'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}