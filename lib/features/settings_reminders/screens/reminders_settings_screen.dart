// lib/features/settings_reminders/screens/reminders_settings_screen.dart
import 'package:dental_ai_app/core/providers/notification_provider.dart';
import 'package:dental_ai_app/core/utils/notification_util.dart';
import 'package:dental_ai_app/features/settings_reminders/widgets/reminder_option_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  Future<void> _selectTime(BuildContext context, WidgetRef ref, int reminderType, TimeOfDay? initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay(hour: (8 + reminderType * 7), minute: 0),
      helpText: 'SELECCIONA HORA PARA RECORDATORIO',
    );
    await ref.read(notificationNotifierProvider.notifier).setReminderTime(reminderType, picked);
  }
  
  Widget _buildPermissionWarningCard(BuildContext context, String text, {VoidCallback? onFix, String buttonText = 'ARREGLAR'}) {
    return Card(
      color: Colors.amber.shade100,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: Colors.amber.shade900)),
            ),
            if (onFix != null) ...[
              const SizedBox(width: 12),
              TextButton(onPressed: onFix, child: Text(buttonText)),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationNotifierProvider);
    final notificationNotifier = ref.read(notificationNotifierProvider.notifier);
    final basicPermissionStatusAsync = ref.watch(notificationPermissionProvider);
    final exactAlarmPermissionAsync = ref.watch(exactAlarmPermissionProvider);
    final batteryOptimizationStatusAsync = ref.watch(batteryOptimizationProvider);

    return Scaffold(
      body: ListView( 
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          basicPermissionStatusAsync.when(
            data: (status) {
              if (status.isGranted) return const SizedBox.shrink();
              return _buildPermissionWarningCard(
                context,
                status.isPermanentlyDenied 
                  ? 'Los permisos de notificación están bloqueados. Habilítalos en los ajustes.' 
                  : 'Para recibir recordatorios, necesitas permitir las notificaciones.',
                onFix: openAppSettings
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => Text('Error al verificar permisos: $e'),
          ),

          exactAlarmPermissionAsync.when(
            data: (status) {
              if (status.isGranted) return const SizedBox.shrink();
              return _buildPermissionWarningCard(
                context,
                'Para asegurar la puntualidad, se necesita el permiso de "Alarmas y recordatorios".',
                onFix: () async {
                  await Permission.scheduleExactAlarm.request();
                  ref.invalidate(exactAlarmPermissionProvider);
                }
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => Text('Error al verificar permiso de alarma: $e'),
          ),
          
          batteryOptimizationStatusAsync.when(
            data: (status) {
              if (status.isGranted) return const SizedBox.shrink();

              return _buildPermissionWarningCard(
                context,
                'Tu teléfono Xiaomi puede cerrar la app para ahorrar batería.\n\nPara asegurar que los recordatorios funcionen, por favor, sigue estos pasos:\n1. Ve a Ajustes > Batería > ⚙️\n2. "Ahorro de batería en aplic."\n3. Busca "Dental AI" y elige "Sin restricciones".\n4. Vuelve atrás y busca "Inicio automático" o "Autostart", y actívalo para "Dental AI".',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e,s) => const SizedBox.shrink(),
          ),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0),
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
                      onChanged: (bool value) async {
                        await notificationNotifier.toggleReminders(value);
                        ref.invalidate(notificationPermissionProvider);
                        ref.invalidate(exactAlarmPermissionProvider);
                        ref.invalidate(batteryOptimizationProvider);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () async {
                      await notificationNotifier.toggleReminders(!notificationSettings.remindersEnabled);
                      ref.invalidate(notificationPermissionProvider);
                      ref.invalidate(exactAlarmPermissionProvider);
                      ref.invalidate(batteryOptimizationProvider);
                    },
                  ),
                  const Divider(),
                  ReminderOptionWidget(
                    leadingIcon: Icons.wb_sunny_outlined,
                    title: 'Recordatorio de Mañana',
                    isEnabled: notificationSettings.remindersEnabled,
                    trailing: Text(notificationSettings.morningReminder?.format(context) ?? 'No establecido', style: TextStyle(fontWeight: FontWeight.bold, color: notificationSettings.remindersEnabled ? Theme.of(context).colorScheme.primary : Colors.grey)),
                    onTap: () => _selectTime(context, ref, 0, notificationSettings.morningReminder),
                  ),
                   ReminderOptionWidget(
                    leadingIcon: Icons.fastfood_outlined,
                    title: 'Recordatorio de Tarde',
                    isEnabled: notificationSettings.remindersEnabled,
                    trailing: Text(notificationSettings.afternoonReminder?.format(context) ?? 'No establecido', style: TextStyle(fontWeight: FontWeight.bold, color: notificationSettings.remindersEnabled ? Theme.of(context).colorScheme.primary : Colors.grey)),
                    onTap: () => _selectTime(context, ref, 1, notificationSettings.afternoonReminder),
                  ),
                   ReminderOptionWidget(
                    leadingIcon: Icons.nightlight_round,
                    title: 'Recordatorio de Noche',
                    isEnabled: notificationSettings.remindersEnabled,
                    trailing: Text(notificationSettings.nightReminder?.format(context) ?? 'No establecido', style: TextStyle(fontWeight: FontWeight.bold, color: notificationSettings.remindersEnabled ? Theme.of(context).colorScheme.primary : Colors.grey)),
                    onTap: () => _selectTime(context, ref, 2, notificationSettings.nightReminder),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.send_and_archive_outlined),
            label: const Text('Probar Notificación Ahora'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enviando notificación de prueba en 5 segundos...'), duration: Duration(seconds: 4)),
              );
              await Future.delayed(const Duration(seconds: 5));
              await notificationNotifier.sendTestNotification();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12)
            ),
          ),
        ],
      ),
    );
  }
}