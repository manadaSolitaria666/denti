// lib/features/map/widgets/clinic_info_panel_widget.dart (Estructura Corregida)
import 'package:dental_ai_app/core/models/clinic_model.dart';
import 'package:dental_ai_app/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicInfoPanelWidget extends StatelessWidget {
  final ClinicModel clinic;
  final UserModel? currentUser;
  final VoidCallback? onClose;

  const ClinicInfoPanelWidget({
    super.key,
    required this.clinic,
    this.currentUser,
    this.onClose,
  });

  Future<void> _launchEmail() async {
    final String? clinicEmail = clinic.email;
    if (clinicEmail == null || clinicEmail.isEmpty) return;

    final String userName = currentUser?.name ?? 'un paciente';
    final String userEmail = currentUser?.email ?? 'no especificado';

    final String subject = Uri.encodeComponent('Solicitud de Cita - App Dental AI');
    final String body = Uri.encodeComponent(
      'Hola, soy $userName.\n\n'
      'Me gustaría solicitar información para agendar una cita en su clínica.\n\n'
      'Mi correo de contacto es: $userEmail\n\n'
      'Gracias.'
    );

    final Uri mailtoUri = Uri.parse('mailto:$clinicEmail?subject=$subject&body=$body');

    if (!await launchUrl(mailtoUri)) {
      // Manejar error
    }
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- INICIO DE LA CORRECCIÓN ---
    // Envolvemos el DraggableScrollableSheet en un LayoutBuilder para darle
    // un contexto de tamaño definido, lo que ayuda a evitar el error de altura infinita.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4, 
          minChildSize: 0.2,    
          maxChildSize: 0.8,     
          expand: false,
          builder: (_, scrollController) {
            // Usamos un widget Material para el fondo y la sombra,
            // que a menudo es más estable que un Container con decoration.
            return Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 8.0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
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
                  if (clinic.description != null && clinic.description!.isNotEmpty)
                    Text(
                      clinic.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                  
                  const Divider(height: 32),
                  
                  if (clinic.email != null && clinic.email!.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Agendar Cita por Correo'),
                      onPressed: _launchEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  
                  if (clinic.email != null && clinic.email!.isNotEmpty)
                    const SizedBox(height: 24),
                  
                  _buildInfoRow(context, Icons.location_on_outlined, clinic.address),
                  if (clinic.operatingHours != null && clinic.operatingHours!.isNotEmpty)
                    _buildInfoRow(context, Icons.access_time_outlined, clinic.operatingHours!),
                  if (clinic.phone != null && clinic.phone!.isNotEmpty)
                    _buildInfoRow(context, Icons.phone_outlined, clinic.phone!),
                  if (clinic.email != null && clinic.email!.isNotEmpty)
                    _buildInfoRow(context, Icons.email_outlined, clinic.email!),
                  if (clinic.website != null && clinic.website!.isNotEmpty)
                    _buildInfoRow(context, FontAwesomeIcons.globe, clinic.website!),

                  if (clinic.servicesOffered.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text("Servicios Ofrecidos", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: clinic.servicesOffered.map((service) => Chip(
                        label: Text(service),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
    // --- FIN DE LA CORRECCIÓN ---
  }
}