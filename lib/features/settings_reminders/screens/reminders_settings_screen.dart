// lib/features/settings_reminders/screens/reminders_settings_screen.dart (Con instrucciones para Xiaomi)
import 'package:dental_ai_app/core/providers/notification_provider.dart';
import 'package:dental_ai_app/features/settings_reminders/widgets/reminder_option_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class RemindersSettingsScreen extends ConsumerWidget {
  const RemindersSettingsScreen({super.key});

  Future<void> _selectTime(BuildContext context, WidgetRef ref, TimeOfDay? initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 20, minute: 0),
      helpText: 'SELECCIONA HORA PARA RECORDATORIO',
    );
    if (picked != null) {
      await ref.read(notificationNotifierProvider.notifier).setReminderTime(picked);
    }
  }
  
  // Widget helper modificado para no requerir un botón
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
            if (onFix != null) ...[ // Solo mostrar el botón si se provee una acción
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
          // Verificador para el permiso BÁSICO de notificaciones
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

          // Verificador para el permiso de ALARMAS EXACTAS
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
          
          // <<<--- INICIO DE CORRECCIÓN PARA XIAOMI ---
          // Aviso sobre optimización de batería con instrucciones claras
          batteryOptimizationStatusAsync.when(
            data: (status) {
              // Solo mostrar si el permiso NO está concedido (es decir, la optimización está activa)
              if (status.isGranted) return const SizedBox.shrink();

              // El botón se elimina porque request() no funciona en MIUI.
              // En su lugar, se muestran instrucciones detalladas.
              return _buildPermissionWarningCard(
                context,
                'Tu teléfono Xiaomi puede cerrar la app para ahorrar batería.\n\nPara asegurar que los recordatorios funcionen:\n1. Ve a Ajustes > Batería\n2. Toca el icono de engranaje (⚙️)\n3. "Ahorro de batería en aplic."\n4. Busca "Dental AI" y elige "Sin restricciones"',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e,s) => const SizedBox.shrink(),
          ),
          // --- FIN DE CORRECCIÓN ---
          
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
                        ref.invalidate(batteryOptimizationProvider); // Re-verificar
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () async {
                      await notificationNotifier.toggleReminders(!notificationSettings.remindersEnabled);
                      ref.invalidate(notificationPermissionProvider);
                      ref.invalidate(exactAlarmPermissionProvider);
                      ref.invalidate(batteryOptimizationProvider); // Re-verificar
                    },
                  ),
                  const Divider(),
                  ReminderOptionWidget(
                    leadingIcon: Icons.access_time_outlined,
                    title: 'Hora del Recordatorio',
                    isEnabled: notificationSettings.remindersEnabled,
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
        ],
      ),
    );
  }
}
