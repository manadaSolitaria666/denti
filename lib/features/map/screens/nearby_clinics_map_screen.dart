// lib/features/map/screens/nearby_clinics_map_screen.dart (Completo y Corregido)
import 'dart:async';
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:dental_ai_app/core/providers/map_provider.dart';
import 'package:dental_ai_app/features/map/widgets/clinic_info_panel_widget.dart';
import 'package:dental_ai_app/features/map/widgets/clinic_map_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyClinicsMapScreen extends ConsumerStatefulWidget {
  const NearbyClinicsMapScreen({super.key});

  @override
  ConsumerState<NearbyClinicsMapScreen> createState() => _NearbyClinicsMapScreenState();
}

class _NearbyClinicsMapScreenState extends ConsumerState<NearbyClinicsMapScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMapData();
    });
  }

  Future<void> _loadMapData() async {
    await _checkLocationPermissionAndFetch();
    if (mounted) {
      await ref.read(mapNotifierProvider.notifier).fetchClinics();
    }
  }
  
  Future<void> _checkLocationPermissionAndFetch() async {
    final status = await Permission.location.status;
    if (!mounted) return;

    if (!status.isGranted) {
      final requestedStatus = await Permission.location.request();
      if (!mounted) return;
      if (requestedStatus.isGranted) {
        await ref.read(mapNotifierProvider.notifier).fetchUserLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de ubicación para mostrar el mapa.')),
        );
        if (requestedStatus.isPermanentlyDenied) _showPermissionDeniedDialog();
      }
    } else {
       final mapState = ref.read(mapNotifierProvider);
       if (mapState.currentUserLocation == null && !mapState.isLoadingLocation) {
         await ref.read(mapNotifierProvider.notifier).fetchUserLocation();
       }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso Denegado'),
        content: const Text('El permiso de ubicación fue denegado. Por favor, habilítalo en los ajustes de la aplicación.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Abrir Ajustes'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateMarkers(List<ClinicModel> clinics, {ClinicModel? selectedClinic}) async {
    final Set<Marker> newMarkers = {};
    for (final clinic in clinics) {
      final bool isSelectedMarker = selectedClinic?.id == clinic.id;
      final BitmapDescriptor icon = await getClinicMarkerIcon(isSelected: isSelectedMarker);

      newMarkers.add(
        Marker(
          markerId: MarkerId(clinic.id),
          position: clinic.position,
          infoWindow: InfoWindow(
            title: clinic.name,
            snippet: 'Toca para ver detalles',
          ),
          onTap: () {
            ref.read(mapNotifierProvider.notifier).selectClinic(clinic);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(clinic.position, 15.5), 
            );
          },
          icon: icon,
          zIndex: isSelectedMarker ? 1.0 : 0.0, 
        ),
      );
    }
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapNotifierProvider);

    ref.listen<List<ClinicModel>>(
      mapNotifierProvider.select((state) => state.nearbyClinics),
      (previous, nextClinics) {
        if (kDebugMode) print("[NearbyClinicsMapScreen] El listener detectó un cambio. Se recibieron ${nextClinics.length} clínicas. Actualizando marcadores...");
        _updateMarkers(nextClinics, selectedClinic: ref.read(mapNotifierProvider).selectedClinic);
      },
    );

    ref.listen<ClinicModel?>(
      mapNotifierProvider.select((state) => state.selectedClinic),
      (previous, next) {
        _updateMarkers(ref.read(mapNotifierProvider).nearbyClinics, selectedClinic: next);
      }
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clínicas y Consultorios'),
        actions: [
          if (mapState.isLoadingLocation || mapState.isLoadingClinics) 
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width:20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMapData,
              tooltip: 'Recargar Clínicas',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (mapState.initialCameraPosition == null)
            Center(
              child: (mapState.errorMessage != null) 
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${mapState.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  )
                : const CircularProgressIndicator(semanticsLabel: "Cargando mapa...")
            )
          else
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: mapState.initialCameraPosition!,
              onMapCreated: (GoogleMapController controller) async { 
                if (!_mapControllerCompleter.isCompleted) {
                   _mapControllerCompleter.complete(controller);
                }
                _mapController = controller;
                if (mapState.nearbyClinics.isNotEmpty) {
                  await _updateMarkers(mapState.nearbyClinics, selectedClinic: mapState.selectedClinic);
                }
              },
              markers: _markers,
              myLocationEnabled: true, 
              myLocationButtonEnabled: true, 
              zoomControlsEnabled: true,
              onTap: (_) { 
                ref.read(mapNotifierProvider.notifier).selectClinic(null);
              },
            ),
          
          // Nuevo: Mostrar mensaje si no se encontraron clínicas
          if (!mapState.isLoadingClinics && mapState.nearbyClinics.isEmpty && mapState.errorMessage == null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No se encontraron clínicas.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          
          if (mapState.selectedClinic != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClinicInfoPanelWidget(
                clinic: mapState.selectedClinic!,
                onClose: () {
                  ref.read(mapNotifierProvider.notifier).selectClinic(null);
                },
              ),
            ),
          
          if (mapState.currentUserLocation != null && _mapController != null)
            Positioned(
              bottom: (mapState.selectedClinic != null ? MediaQuery.of(context).size.height * 0.3 + 20 : 20) + (MediaQuery.of(context).padding.bottom > 0 ? 0 : 20),
              right: 20,
              child: FloatingActionButton.small(
                heroTag: "center_location_fab", 
                onPressed: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(mapState.currentUserLocation!, 15.0),
                  );
                },
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}
