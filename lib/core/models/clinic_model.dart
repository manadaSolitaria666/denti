// lib/core/models/clinic_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClinicModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final LatLng position; // Coordenadas para el mapa
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final List<String> servicesOffered;
  // Puedes añadir más campos como horarios, etc.

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
  });

  // Factory constructor para crear desde un DocumentSnapshot de Firestore
  factory ClinicModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    // Extraer el GeoPoint y convertirlo a LatLng
    final geoPoint = data['location'] as GeoPoint? ?? const GeoPoint(0, 0);
    final position = LatLng(geoPoint.latitude, geoPoint.longitude);

    // Extraer la lista de servicios
    final services = data['servicesOffered'] as List<dynamic>? ?? [];
    final List<String> servicesList = services.map((service) => service.toString()).toList();

    return ClinicModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Nombre no disponible',
      address: data['address'] as String? ?? 'Dirección no disponible',
      position: position,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      description: data['description'] as String?,
      servicesOffered: servicesList,
    );
  }

  @override
  List<Object?> get props => [id, name, address, position, phone, email, website, description, servicesOffered];
}