// lib/features/map/widgets/clinic_map_marker.dart
import 'package:flutter/foundation.dart'; // Necesario para kIsWeb
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:dental_ai_app/core/models/clinic_model.dart'; // Descomentar si se necesita lógica basada en el modelo

// Helper function to get a marker icon.
// This can be expanded to load custom images from assets.
Future<BitmapDescriptor> getClinicMarkerIcon({
  bool isSelected = false,
  // ClinicModel? clinic, // Podrías pasar el modelo para lógica más compleja (ej. diferentes iconos por tipo/rating)
}) async {
  // En la web, BitmapDescriptor.fromAssetImage puede tener problemas con el hot restart/reload a veces.
  // Usar defaultMarker es más robusto para la web si no se necesitan assets complejos.
  if (kIsWeb) {
    return BitmapDescriptor.defaultMarkerWithHue(
      isSelected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueAzure,
    );
  }

  // Para móvil, podrías cargar desde assets si tuvieras iconos personalizados.
  // Ejemplo (requiere 'assets/icons/custom_marker.png' y 'assets/icons/custom_marker_selected.png'):
  /*
  try {
    if (isSelected) {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(64, 64)), // Ajusta el tamaño según tu asset
        'assets/icons/custom_marker_selected.png',
      );
    }
    return await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/icons/custom_marker.png',
    );
  } catch (e) {
    // print("Error cargando BitmapDescriptor desde asset: $e");
    // Fallback a default marker si el asset no carga
    return BitmapDescriptor.defaultMarkerWithHue(
      isSelected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueAzure,
    );
  }
  */

  // Por ahora, retornamos el default coloreado para todas las plataformas (móvil y web)
  // si no se usa el ejemplo de assets de arriba.
  return BitmapDescriptor.defaultMarkerWithHue(
    isSelected ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueAzure,
  );
}
