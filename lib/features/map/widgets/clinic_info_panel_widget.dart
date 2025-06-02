// lib/features/map/widgets/clinic_info_panel_widget.dart
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class ClinicInfoPanelWidget extends StatelessWidget {
  final ClinicModel clinic;
  final VoidCallback? onClose;

  const ClinicInfoPanelWidget({
    super.key,
    required this.clinic,
    this.onClose,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Consider showing a Snackbar or log if launching fails
      // print('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3, 
      minChildSize: 0.15,    
      maxChildSize: 0.6,     
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // Use cardColor for better theme adaptation
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1, // Reduced spread
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      clinic.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      // overflow: TextOverflow.ellipsis, // Removed for multi-line if needed
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      tooltip: "Cerrar",
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 20), // Darker amber
                  const SizedBox(width: 4),
                  Text(
                    '${clinic.rating.toStringAsFixed(1)} estrellas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                clinic.address,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(height: 24),
              if (clinic.phoneNumber != null && clinic.phoneNumber!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(clinic.phoneNumber!),
                  onTap: () => _launchUrl('tel:${clinic.phoneNumber}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              if (clinic.website != null && clinic.website!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(
                    clinic.website!, 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary, 
                      decoration: TextDecoration.underline
                    )
                  ),
                  onTap: () => _launchUrl(clinic.website!),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Obtener Direcciones'),
                onPressed: () {
                  String googleMapsUrl;
                  if (clinic.position.latitude != 0 && clinic.position.longitude != 0) {
                     googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${clinic.position.latitude},${clinic.position.longitude}';
                  } else {
                     googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(clinic.address)}';
                  }
                  _launchUrl(googleMapsUrl);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
