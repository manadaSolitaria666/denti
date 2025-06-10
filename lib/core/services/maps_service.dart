// lib/core/services/maps_service.dart (Corregido y Simplificado)
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class MapsService {
  // Ya no necesitamos la API Key de Google Maps aquí,
  // ya que solo obtenemos la ubicación del dispositivo.

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current position: $e');
      }
      return Future.error('Error al obtener la ubicación actual: ${e.toString()}');
    }
  }

  // El método findNearbyDentalClinics se ha eliminado porque ahora
  // las clínicas se obtienen directamente desde FirestoreService.
}

// Provider para MapsService
final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService();
});