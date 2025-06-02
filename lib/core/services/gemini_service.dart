// lib/core/services/gemini_service.dart
import 'dart:convert';
// Necesario para Gemini SDK
import 'dart:io';
import 'package:dental_ai_app/core/constants/api_constants.dart'; // Donde guardarías tu API Key
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Necesitas esta corrección si usas el SDK de Gemini con Flutter.
// Crea un archivo dart_convert_fix.dart en tu proyecto (ej. en lib/core/utils)
// y pega el contenido que se muestra al final de este bloque de código.

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest', // O el modelo que prefieras y sea compatible con imágenes
          apiKey: apiKey,
          // Opcional: Configuración de seguridad y generación
          // safetySettings: [
          //   SafetySetting(HarmCategory.harassment, HarmBlockThreshold.mediumAndAbove),
          // ],
          // generationConfig: GenerationConfig(
          //   // temperature: 0.7,
          //   // maxOutputTokens: 2048,
          // )
        );

  Future<Map<String, String>> analyzeDentalData({
    required Map<String, dynamic> formData, // Datos del formulario del usuario
    required List<File> imageFiles, // Lista de archivos de imágenes dentales
  }) async {
    try {
      // 1. Construir el prompt para Gemini
      // Este es un ejemplo muy básico. Deberás refinarlo significativamente.
      final StringBuffer promptBuffer = StringBuffer();
      promptBuffer.writeln("Analiza la siguiente información dental y las imágenes para identificar posibles problemas y ofrecer recomendaciones.");
      promptBuffer.writeln("--- Datos del Formulario ---");
      formData.forEach((key, value) {
        promptBuffer.writeln("$key: $value");
      });
      promptBuffer.writeln("--- Imágenes Adjuntas ---");
      promptBuffer.writeln("Por favor, describe los hallazgos en cada imagen y correlaciónalos con los datos del formulario.");
      promptBuffer.writeln("--- Formato de Respuesta Esperado ---");
      promptBuffer.writeln("Quiero la respuesta en formato JSON con dos claves principales: 'identifiedSigns' (string con los signos identificados) y 'recommendations' (string con las recomendaciones).");
      promptBuffer.writeln("Ejemplo de JSON: {\"identifiedSigns\": \"Signos de posible caries en molar superior derecho. Ligera inflamación gingival.\", \"recommendations\": \"Recomendamos visitar a un dentista para una revisión detallada. Mantener una buena higiene bucal cepillando tres veces al día y usando hilo dental.\"}");


      // 2. Preparar las partes del contenido (texto e imágenes)
      final List<DataPart> imageParts = [];
      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        // Determinar el mimeType (ej. image/jpeg, image/png)
        // Esto es simplificado, podrías usar 'mime' package para más precisión
        String mimeType = 'image/jpeg';
        if (imageFile.path.endsWith('.png')) {
          mimeType = 'image/png';
        }
        imageParts.add(DataPart(mimeType, bytes));
      }

      final content = [
        Content.multi([
          TextPart(promptBuffer.toString()),
          ...imageParts,
        ])
      ];

      // 3. Enviar la solicitud a Gemini
      final response = await _model.generateContent(content);

      // 4. Procesar la respuesta
      if (response.text != null) {
        // print("Respuesta de Gemini: ${response.text}");
        try {
          // Intentar parsear como JSON
          final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
          final signs = jsonResponse['identifiedSigns'] as String? ?? "No se pudieron extraer los signos.";
          final recommendations = jsonResponse['recommendations'] as String? ?? "No se pudieron extraer las recomendaciones.";
          return {
            'identifiedSigns': signs,
            'recommendations': recommendations,
            'rawResponse': response.text!, // Guardar también la respuesta cruda
          };
        } catch (e) {
          // Si no es JSON o el formato es incorrecto, devolver la respuesta como texto plano
          // print("Error al parsear JSON de Gemini: $e. Respuesta cruda: ${response.text}");
          return {
            'identifiedSigns': "Error al procesar la respuesta del IA.",
            'recommendations': "Por favor, intente de nuevo o contacte a soporte. Respuesta cruda: ${response.text}",
            'rawResponse': response.text!,
          };
        }
      } else {
        // print("Respuesta de Gemini vacía o con error: ${response.promptFeedback}");
        throw Exception('No se recibió respuesta del análisis IA. ${response.promptFeedback}');
      }
    } catch (e) {
      // print('Error en GeminiService: $e');
      throw Exception('Error al comunicarse con el servicio de IA: ${e.toString()}');
    }
  }
}

// Provider para GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  // ¡IMPORTANTE! Carga tu API Key de forma segura.
  // NO LA INCLUYAS DIRECTAMENTE EN EL CÓDIGO EN PRODUCCIÓN.
  // Usa variables de entorno o un servicio de configuración.
  const apiKey = ApiConstants.geminiApiKey; // Reemplaza con tu API Key
  if (apiKey.isEmpty || apiKey == "TU_API_KEY_DE_GEMINI_AQUI") {
    throw Exception("API Key de Gemini no configurada. Por favor, añádela en core/constants/api_constants.dart");
  }
  return GeminiService(apiKey);
});
