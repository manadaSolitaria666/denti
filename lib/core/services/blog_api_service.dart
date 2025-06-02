// lib/core/services/blog_api_service.dart
import 'dart:convert';
import 'package:dental_ai_app/core/constants/api_constants.dart';
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BlogApiService {
  // Asume que tienes una URL base para tu API de blog
  final String _baseUrl = ApiConstants.blogApiBaseUrl; 

  Future<List<BlogPostModel>> getBlogPosts() async {
    if (_baseUrl.isEmpty || _baseUrl == "URL_DE_TU_API_DE_BLOG_AQUI") {
      // print("URL de la API del blog no configurada. Devolviendo lista vacía.");
      // Considera lanzar una excepción o manejarlo de forma más robusta.
      return []; // Devuelve lista vacía si no está configurado para evitar crash
    }

    final Uri url = Uri.parse('$_baseUrl/articles'); // Asume un endpoint /articles

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body) as List<dynamic>;
        return jsonData.map((jsonItem) => BlogPostModel.fromJson(jsonItem as Map<String, dynamic>)).toList();
      } else {
        // print('Error al obtener posts del blog: ${response.statusCode} ${response.body}');
        throw Exception('Error al cargar los artículos del blog (${response.statusCode})');
      }
    } catch (e) {
      // print('Excepción al obtener posts del blog: $e');
      throw Exception('No se pudo conectar al servicio del blog: ${e.toString()}');
    }
  }

  Future<BlogPostModel> getBlogPostById(String id) async {
     if (_baseUrl.isEmpty || _baseUrl == "URL_DE_TU_API_DE_BLOG_AQUI") {
      throw Exception("URL de la API del blog no configurada.");
    }
    final Uri url = Uri.parse('$_baseUrl/articles/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return BlogPostModel.fromJson(jsonData as Map<String, dynamic>);
      } else {
        // print('Error al obtener post del blog por ID: ${response.statusCode} ${response.body}');
        throw Exception('Error al cargar el artículo del blog ($response.statusCode)');
      }
    } catch (e) {
      // print('Excepción al obtener post del blog por ID: $e');
      throw Exception('No se pudo conectar al servicio del blog: ${e.toString()}');
    }
  }
}

// Provider para BlogApiService
final blogApiServiceProvider = Provider<BlogApiService>((ref) {
  return BlogApiService();
});