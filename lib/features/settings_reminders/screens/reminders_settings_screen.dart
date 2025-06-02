// lib/features/settings_reminders/screens/reminders_settings_screen.dart
import 'package:dental_ai_app/core/providers/notification_provider.dart';
import 'package:dental_ai_app/features/settings_reminders/widgets/reminder_option_widget.dart'; // Importar el nuevo widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  Future<void> _selectTime(BuildContext context, WidgetRef ref, TimeOfDay? initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 20, minute: 0), // Hora por defecto 8 PM
      helpText: 'SELECCIONA HORA PARA RECORDATORIO',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(notificationNotifierProvider.notifier).setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationNotifierProvider);
    final notificationNotifier = ref.read(notificationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes y Recordatorios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0), // Ajustar padding interno de la Card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Recordatorios de Higiene Bucal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Recibe notificaciones para recordar cepillarte los dientes y usar hilo dental.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReminderOptionWidget(
                    leadingIcon: notificationSettings.remindersEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    iconColor: notificationSettings.remindersEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    title: 'Activar Recordatorios',
                    trailing: Switch(
                      value: notificationSettings.remindersEnabled,
                      onChanged: (bool value) {
                        notificationNotifier.toggleReminders(value);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () { // Para que el Switch sea el único punto de interacción para cambiar el valor
                        notificationNotifier.toggleReminders(!notificationSettings.remindersEnabled);
                    },
                  ),
                  const Divider(),
                  ReminderOptionWidget(
                    leadingIcon: Icons.access_time_outlined,
                    title: 'Hora del Recordatorio',
                    isEnabled: notificationSettings.remindersEnabled,
                    iconColor: notificationSettings.remindersEnabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                    trailing: Text(
                      notificationSettings.reminderTime?.format(context) ?? 'No establecida',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: notificationSettings.remindersEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    onTap: () => _selectTime(context, ref, notificationSettings.reminderTime),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ReminderOptionWidget( // Usando el widget para "Acerca de"
              leadingIcon: Icons.info_outline,
              title: 'Acerca de la App',
              subtitle: 'Versión 1.0.0', // Puedes obtener esto dinámicamente
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Dental AI App',
                  applicationVersion: '1.0.0', // Reemplaza con la versión real
                  applicationLegalese: '© ${DateTime.now().year} Tu Nombre/Compañía. Todos los derechos reservados.',
                  applicationIcon: const Icon(Icons.medical_services_outlined, size: 40), // Tu logo
                  children: <Widget>[
                    const SizedBox(height: 16),
                    const Text('Esta aplicación utiliza Inteligencia Artificial para proporcionar análisis preliminares de salud dental. No reemplaza la consulta con un profesional dental calificado.'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

