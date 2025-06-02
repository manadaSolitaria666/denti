// lib/core/services/maps_service.dart
import 'package:dental_ai_app/core/constants/api_constants.dart';
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para kDebugMode

class MapsService {
  final String _googleMapsApiKey = ApiConstants.googleMapsApiKey;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Considera mostrar un mensaje al usuario o manejarlo de forma más elegante
      if (kDebugMode) {
        print('Location services are disabled.');
      }
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('Location permissions are denied.');
        }
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (kDebugMode) {
        print('Location permissions are permanently denied.');
      }
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high // Puedes ajustar la precisión
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current position: $e');
      }
      return Future.error('Error al obtener la ubicación actual: ${e.toString()}');
    }
  }

  Future<List<ClinicModel>> findNearbyDentalClinics(LatLng location, {double radius = 5000}) async {
    if (_googleMapsApiKey.isEmpty || _googleMapsApiKey == "TU_API_KEY_DE_GOOGLE_MAPS_AQUI") {
       if (kDebugMode) {
         print("API Key de Google Maps no configurada.");
       }
       throw Exception("API Key de Google Maps no configurada.");
    }
    
    // URL Corregida
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=$radius&type=dentist&key=$_googleMapsApiKey&language=es';

    if (kDebugMode) {
      print("Requesting Google Places API URL: $url");
    }

    try {
      final response = await http.get(Uri.parse(url));
      
      if (kDebugMode) {
        print("Google Places API Response Status: ${response.statusCode}");
        // print("Google Places API Response Body: ${response.body}"); // Cuidado con imprimir bodies muy largos
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List results = data['results'] as List? ?? []; // Manejar 'results' nulo
          return results
              .map((place) {
                try {
                  return ClinicModel.fromGooglePlacesJson(place as Map<String,dynamic>);
                } catch (e) {
                  if (kDebugMode) {
                    print("Error parsing clinic data: $e for place: $place");
                  }
                  return null; // O manejar el error de forma diferente
                }
              })
              .whereType<ClinicModel>() // Filtrar los nulos si hubo errores de parseo
              .where((clinic) => clinic.rating >= 4.0) 
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
            if (kDebugMode) {
              print('Google Places API: No se encontraron resultados para la búsqueda.');
            }
            return []; // Devolver lista vacía si no hay resultados
        } else {
          if (kDebugMode) {
            print('Error de Google Places API: ${data['status']} - ${data['error_message']}');
          }
          throw Exception('Error al buscar clínicas (${data['status']}): ${data['error_message'] ?? "Error desconocido de la API."}');
        }
      } else {
        throw Exception('Error de red al buscar clínicas (Código: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Excepción al buscar clínicas: $e');
      }
      // Considera si quieres relanzar la excepción o devolver una lista vacía/manejar el error de otra forma.
      // Por ahora, relanzamos para que el llamador (MapNotifier) pueda manejarlo.
      rethrow; 
    }
  }
}

// Provider para MapsService
final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService();
});
