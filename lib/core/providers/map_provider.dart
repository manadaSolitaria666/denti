// lib/core/providers/map_provider.dart
import 'dart:async';
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:dental_ai_app/core/services/maps_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapState {
  final bool isLoadingLocation;
  final bool isLoadingClinics;
  final LatLng? currentUserLocation;
  final List<ClinicModel> nearbyClinics;
  final ClinicModel? selectedClinic;
  final String? errorMessage;
  final CameraPosition? initialCameraPosition;

  MapState({
    this.isLoadingLocation = false, // Inicia en false, se activa al llamar a fetch
    this.isLoadingClinics = false,
    this.currentUserLocation,
    this.nearbyClinics = const [],
    this.selectedClinic,
    this.errorMessage,
    this.initialCameraPosition,
  });

  MapState copyWith({
    bool? isLoadingLocation,
    bool? isLoadingClinics,
    LatLng? currentUserLocation,
    List<ClinicModel>? nearbyClinics,
    ClinicModel? selectedClinic,
    String? errorMessage,
    bool clearError = false,
    CameraPosition? initialCameraPosition,
    bool deselectClinic = false,
  }) {
    return MapState(
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isLoadingClinics: isLoadingClinics ?? this.isLoadingClinics,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      nearbyClinics: nearbyClinics ?? this.nearbyClinics,
      selectedClinic: deselectClinic ? null : selectedClinic ?? this.selectedClinic,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      initialCameraPosition: initialCameraPosition ?? this.initialCameraPosition,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final MapsService _mapsService;

  MapNotifier(this._mapsService) : super(MapState());

  Future<void> fetchInitialLocationAndClinics() async {
    if (state.isLoadingLocation) return;

    state = state.copyWith(isLoadingLocation: true, clearError: true);
    try {
      final position = await _mapsService.getCurrentLocation();
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      state = state.copyWith(
        currentUserLocation: currentLocation,
        initialCameraPosition: CameraPosition(target: currentLocation, zoom: 14.0),
        isLoadingLocation: false,
      );
      await fetchNearbyClinics(currentLocation);
    } catch (e) {
      state = state.copyWith(isLoadingLocation: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchNearbyClinics(LatLng location, {double radius = 5000}) async {
    if (state.isLoadingClinics) return;

    state = state.copyWith(isLoadingClinics: true, clearError: true);
    try {
      final clinics = await _mapsService.findNearbyDentalClinics(location, radius: radius);
      state = state.copyWith(nearbyClinics: clinics, isLoadingClinics: false);
    } catch (e) {
      state = state.copyWith(isLoadingClinics: false, errorMessage: e.toString());
    }
  }

  void selectClinic(ClinicModel? clinic) {
    if (clinic == null) {
      state = state.copyWith(deselectClinic: true);
    } else {
      state = state.copyWith(selectedClinic: clinic);
    }
  }

}

final mapNotifierProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref.watch(mapsServiceProvider));
});