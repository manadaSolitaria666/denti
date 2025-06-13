// lib/core/models/clinic_model.dart (Corregido para manejar GeoPoint y tipos de datos inconsistentes)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class ClinicModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> servicesOffered;
  final String? operatingHours;

  const ClinicModel({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.servicesOffered = const [],
    this.operatingHours,
  });

  factory ClinicModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // --- Manejo robusto de la ubicación ---
    LatLng position;
    final dynamic locationData = data['location'];

    if (locationData is GeoPoint) {
      position = LatLng(locationData.latitude, locationData.longitude);
    } else if (locationData is Map) {
      try {
        final lat = (locationData['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (locationData['longitude'] as num?)?.toDouble() ?? 0.0;
        position = LatLng(lat, lng);
      } catch (e) {
        if (kDebugMode) print("Error al parsear el mapa de ubicación para la clínica ${doc.id}: $e");
        position = const LatLng(0, 0);
      }
    } else {
      if (kDebugMode) print("El campo 'location' falta o tiene un tipo inesperado para la clínica ${doc.id}.");
      position = const LatLng(0, 0);
    }
    
    // --- Manejo robusto de la lista de servicios ---
    final services = data['servicesOffered'] as List<dynamic>? ?? [];
    final List<String> servicesList = services.map((service) => service.toString()).toList();

    return ClinicModel(
      id: doc.id,
      // --- INICIO DE LA CORRECCIÓN: Conversión segura a String ---
      // Usar ?.toString() asegura que el valor se convierta a String sin importar
      // si en Firestore es un número o un texto, evitando errores de tipo.
      name: data['name']?.toString() ?? 'Nombre no disponible',
      address: data['address']?.toString() ?? 'Dirección no disponible',
      position: position,
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      website: data['website']?.toString(),
      description: data['description']?.toString(),
      servicesOffered: servicesList,
      operatingHours: data['operatingHours_monday']?.toString(), // Mapeo del nuevo campo de horario
      // --- FIN DE LA CORRECCIÓN ---
    );
  }

  @override
  List<Object?> get props => [id, name, address, position, phone, email, website, description, servicesOffered, operatingHours];
}