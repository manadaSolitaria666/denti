// lib/features/map/screens/nearby_clinics_map_screen.dart
import 'dart:async';
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:dental_ai_app/core/providers/map_provider.dart';
import 'package:dental_ai_app/features/map/widgets/clinic_info_panel_widget.dart'; 
import 'package:dental_ai_app/features/map/widgets/clinic_map_marker.dart';
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
      // Intentar cargar la ubicación y clínicas al iniciar la pantalla
      // si los permisos ya están concedidos o se conceden ahora.
      _checkLocationPermissionAndFetch();
    });
  }
  
  Future<void> _checkLocationPermissionAndFetch() async {
    final status = await Permission.location.status;
    if (!mounted) return;

    if (!status.isGranted) {
      final requestedStatus = await Permission.location.request();
      if (!mounted) return;
      if (requestedStatus.isGranted) {
        ref.read(mapNotifierProvider.notifier).fetchInitialLocationAndClinics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso de ubicación para encontrar clínicas cercanas.')),
        );
        if (requestedStatus.isPermanentlyDenied) _showPermissionDeniedDialog();
      }
    } else {
       final mapState = ref.read(mapNotifierProvider);
       // CORRECCIÓN AQUÍ: Usar isLoadingLocation
       if (mapState.currentUserLocation == null && !mapState.isLoadingLocation) {
         ref.read(mapNotifierProvider.notifier).fetchInitialLocationAndClinics();
       } else if (mapState.currentUserLocation != null && mapState.nearbyClinics.isEmpty && !mapState.isLoadingClinics) {
         ref.read(mapNotifierProvider.notifier).fetchNearbyClinics(mapState.currentUserLocation!);
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
            snippet: 'Rating: ${clinic.rating.toStringAsFixed(1)}',
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
        _updateMarkers(nextClinics, selectedClinic: ref.read(mapNotifierProvider).selectedClinic);
      },
    );

    ref.listen<ClinicModel?>(
      mapNotifierProvider.select((state) => state.selectedClinic),
      (previousSelected, nextSelected) {
        _updateMarkers(ref.read(mapNotifierProvider).nearbyClinics, selectedClinic: nextSelected);
      }
    );


    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultorios Cercanos'),
        actions: [
          // Usar los flags específicos de carga
          if (mapState.isLoadingLocation || mapState.isLoadingClinics) 
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width:20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(mapNotifierProvider.notifier).fetchInitialLocationAndClinics();
              },
              tooltip: 'Recargar Clínicas',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (mapState.errorMessage != null && mapState.initialCameraPosition == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${mapState.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _checkLocationPermissionAndFetch,
                      child: const Text("Reintentar Cargar Ubicación")
                    )
                  ],
                ),
              ),
            )
          else if (mapState.initialCameraPosition == null)
            const Center(child: CircularProgressIndicator(semanticsLabel: "Cargando mapa..."))
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
