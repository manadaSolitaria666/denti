// lib/core/services/gemini_service.dart
import 'dart:convert';
import 'package:dental_ai_app/core/utils/dart_convert_fix.dart';
import 'dart:io';
import 'package:dental_ai_app/core/constants/api_constants.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final GenerativeModel? _model;
  final bool _isConfigured;

  GeminiService(String apiKey)
      : _isConfigured = !(apiKey.isEmpty || apiKey == "AIzaSyDknfYVsXBgW2yg51IFeJWyyrYYsTbw4pg"),
        _model = (apiKey.isEmpty || apiKey == "AIzaSyDknfYVsXBgW2yg51IFeJWyyrYYsTbw4pg")
            ? null
            : GenerativeModel(
                model: 'gemini-1.5-flash-latest',
                apiKey: apiKey,
                generationConfig: GenerationConfig(
                  responseMimeType: 'application/json',
                ),
              );

  String _fixJsonString(String jsonString) {
    String fixedJson = jsonString.replaceAll(RegExp(r'[\n\r\t]'), '');
    fixedJson = fixedJson.replaceAll(RegExp(r',\s*(?=[\}\]])'), '');
    return fixedJson;
  }

  Future<Map<String, dynamic>> analyzeDentalData({
    required Map<String, dynamic> formData,
    required List<File> imageFiles,
  }) async {
    if (!_isConfigured || _model == null) {
      return {'error': 'El servicio de IA no está configurado. Por favor, añade la API Key.'};
    }

    final String fullPrompt;
    try {
      final StringBuffer promptBuffer = StringBuffer();
      promptBuffer.writeln("Eres un asistente dental virtual diseñado para realizar un pre-diagnóstico basado en un cuestionario y fotografías. Tu objetivo es identificar posibles problemas, evaluar un nivel de urgencia y proporcionar recomendaciones claras.");
      promptBuffer.writeln("Analiza el siguiente cuestionario y las imágenes adjuntas. Basado en TODA la información, devuelve un objeto JSON válido con la siguiente estructura y claves:");
      promptBuffer.writeln("{");
      promptBuffer.writeln("  \"overallSummary\": \"(string) Un resumen conciso y fácil de entender del estado general del paciente en 2-3 frases.\",");
      promptBuffer.writeln("  \"possibleConditions\": \"(array of strings) Una lista de posibles condiciones o problemas identificados (ej: 'Caries extensas', 'Signos de gingivitis', 'Posible maloclusión', 'Sensibilidad dental').\",");
      promptBuffer.writeln("  \"severityLevel\": \"(string) Un nivel de urgencia o severidad. Debe ser uno de los siguientes: 'Bajo', 'Moderado', 'Alto', 'Urgente'.\",");
      promptBuffer.writeln("  \"detailedRecommendations\": \"(string) Recomendaciones detalladas y específicas en un solo bloque de texto. Usa saltos de línea (\\n) para separar puntos y crear párrafos. Incluye consejos de higiene y cuidado general.\",");
      promptBuffer.writeln("  \"nextSteps\": \"(string) El siguiente paso claro y directo que el paciente debe tomar (ej: 'Se recomienda agendar una cita con un dentista para una evaluación completa y un plan de tratamiento.').\"");
      promptBuffer.writeln("}");
      promptBuffer.writeln("--- CUESTIONARIO DEL PACIENTE ---");
      formData.forEach((key, value) {
        promptBuffer.writeln("- $key: $value");
      });
      fullPrompt = promptBuffer.toString();

      final List<DataPart> imageParts = [];
      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        String mimeType = 'image/jpeg';
        if (imageFile.path.endsWith('.png')) mimeType = 'image/png';
        imageParts.add(DataPart(mimeType, bytes));
      }

      final content = [Content.multi([TextPart(fullPrompt), ...imageParts])];
      final response = await _model!.generateContent(content);
      final rawResponseText = response.text;

      if (rawResponseText == null || rawResponseText.isEmpty) {
        throw Exception('La respuesta del análisis IA está vacía.');
      }
      
      if (kDebugMode) print("--- Respuesta Cruda de Gemini ---\n$rawResponseText\n-----------------------------");

      String jsonString = rawResponseText;
      if (!jsonString.trim().startsWith('{')) {
          final startIndex = rawResponseText.indexOf('{');
          final endIndex = rawResponseText.lastIndexOf('}');
          if (startIndex != -1 && endIndex != -1) {
            jsonString = rawResponseText.substring(startIndex, endIndex + 1);
          } else {
             throw const FormatException("La respuesta de la IA no contiene un objeto JSON válido.");
          }
      }

      final repairedJson = _fixJsonString(jsonString);

      try {
        final jsonResponse = jsonDecode(repairedJson) as Map<String, dynamic>;
        
        return {
          ...jsonResponse,
          'rawResponse': rawResponseText,
          'fullPrompt': fullPrompt,
        };

      } catch (e) {
        if (kDebugMode) print("--- Error al decodificar JSON ---\nError: $e\nJSON que falló: $repairedJson\n-----------------------------");
        throw FormatException("El formato del JSON recibido de la IA es incorrecto, incluso después de limpiar.");
      }
    } catch (e) {
      if (kDebugMode) print('Error general en GeminiService: $e');
      return {'error': 'Error al comunicarse con el servicio IA: ${e.toString()}'};
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  const apiKey = ApiConstants.geminiApiKey;
  return GeminiService(apiKey);
});