// lib/core/models/clinic_model.dart
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClinicModel extends Equatable {
  final String id; // Podría ser el place_id de Google Places
  final String name;
  final String address;
  final LatLng position;
  final double rating; // Rating de Google (ej. 4.5)
  final String? phoneNumber;
  final String? website;
  // Otros campos que puedas obtener de la API de Google Places

  const ClinicModel({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.rating,
    this.phoneNumber,
    this.website,
  });

  // Este es un ejemplo, la estructura dependerá de la respuesta de la API de Google Places
  factory ClinicModel.fromGooglePlacesJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['place_id'] as String,
      name: json['name'] as String,
      address: json['vicinity'] ?? json['formatted_address'] as String? ?? 'Dirección no disponible',
      position: LatLng(
        json['geometry']['location']['lat'] as double,
        json['geometry']['location']['lng'] as double,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: json['formatted_phone_number'] as String?,
      website: json['website'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, address, position, rating, phoneNumber, website];
}