// lib/core/services/gemini_service.dart
import 'dart:convert';
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

  // NUEVO: Función para convertir una lista o un string a un solo string formateado.
  String _formatResponseValue(dynamic value) {
    if (value is List) {
      if (value.isEmpty) return "No hay datos específicos.";
      // Formatea la lista con viñetas (•)
      return value.map((item) => '• ${item.toString()}').join('\n');
    } else if (value is String) {
      return value;
    }
    // Valor por defecto si el formato es inesperado
    return "Dato no disponible en el formato esperado.";
  }

  Future<Map<String, String>> analyzeDentalData({
    required Map<String, dynamic> formData,
    required List<File> imageFiles,
  }) async {
    if (!_isConfigured || _model == null) {
      return {
        'error': 'El servicio de IA no está configurado. Por favor, añade la API Key de Gemini en los ajustes.',
        'rawResponse': 'No configurado',
        'fullPrompt': 'N/A',
      };
    }

    final String fullPrompt;
    try {
      final StringBuffer promptBuffer = StringBuffer();
      // Ajuste en el prompt para guiar mejor a la IA
      promptBuffer.writeln("Analiza la siguiente información dental y las imágenes adjuntas. Devuelve un objeto JSON con dos claves: 'identifiedSigns' (una lista de strings con los hallazgos) y 'recommendations' (una lista de strings con las recomendaciones).");
      promptBuffer.writeln("--- Datos del Formulario ---");
      formData.forEach((key, value) {
        promptBuffer.writeln("$key: $value");
      });
      
      fullPrompt = promptBuffer.toString();

      final List<DataPart> imageParts = [];
      for (final imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        String mimeType = 'image/jpeg';
        if (imageFile.path.endsWith('.png')) {
          mimeType = 'image/png';
        }
        imageParts.add(DataPart(mimeType, bytes));
      }

      final content = [
        Content.multi([
          TextPart(fullPrompt),
          ...imageParts,
        ])
      ];

      final response = await _model.generateContent(content);
      final rawResponseText = response.text;

      if (rawResponseText == null || rawResponseText.isEmpty) {
        throw Exception('La respuesta del análisis IA está vacía.');
      }
      
      if (kDebugMode) {
        print("--- Respuesta Cruda de Gemini ---");
        print(rawResponseText);
        print("--------------------------------");
      }

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
        
        // CORRECCIÓN: Usar la nueva función para procesar los valores
        final signs = _formatResponseValue(jsonResponse['identifiedSigns']);
        final recommendations = _formatResponseValue(jsonResponse['recommendations']);
        
        return {
          'identifiedSigns': signs.isEmpty ? "No se pudieron extraer los signos." : signs,
          'recommendations': recommendations.isEmpty ? "No se pudieron extraer las recomendaciones." : recommendations,
          'rawResponse': rawResponseText,
          'fullPrompt': fullPrompt,
        };
      } catch (e) {
        if (kDebugMode) {
          print("--- Error al decodificar JSON ---");
          print("Error: $e");
          print("JSON que falló (después de reparar): $repairedJson");
          print("---------------------------------");
        }
        throw FormatException("El formato del JSON recibido de la IA es incorrecto, incluso después de limpiar.");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error general en GeminiService: $e');
      }
      return {
        'error': 'Error al comunicarse con el servicio IA: ${e.toString()}',
        'rawResponse': 'Sin respuesta',
        'fullPrompt': 'No se pudo generar el prompt',
      };
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  const apiKey = ApiConstants.geminiApiKey;
  return GeminiService(apiKey);
});