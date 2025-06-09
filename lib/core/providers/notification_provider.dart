// lib/core/providers/notification_provider.dart (Con nuevo provider de optimización de batería)
import 'package:dental_ai_app/core/utils/notification_util.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _remindersEnabledKey = 'remindersEnabled';
const String _reminderHourKey = 'reminderHour';
const String _reminderMinuteKey = 'reminderMinute';

class NotificationSettings {
  final bool remindersEnabled;
  final TimeOfDay? reminderTime;
  NotificationSettings({this.remindersEnabled = false, this.reminderTime});

  NotificationSettings copyWith({bool? remindersEnabled, TimeOfDay? reminderTime, bool clearTime = false}) {
    return NotificationSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: clearTime ? null : reminderTime ?? this.reminderTime,
    );
  }
}

final notificationPermissionProvider = FutureProvider.autoDispose<PermissionStatus>((ref) async {
  return await Permission.notification.status;
});

final exactAlarmPermissionProvider = FutureProvider.autoDispose<PermissionStatus>((ref) async {
  return await Permission.scheduleExactAlarm.status;
});

// NUEVO: Provider para verificar el estado del permiso de optimización de batería
final batteryOptimizationProvider = FutureProvider.autoDispose<PermissionStatus>((ref) async {
  return await Permission.ignoreBatteryOptimizations.status;
});


class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async { /* ...código sin cambios... */ }
  Future<void> _saveSettings() async { /* ...código sin cambios... */ }

  Future<void> _scheduleNotification(TimeOfDay time) async {
    await NotificationUtil.scheduleDailyNotification(
      id: 0,
      title: 'Recordatorio de Higiene Bucal',
      body: '¡Es hora de cuidar tu sonrisa! No olvides cepillarte y usar hilo dental.',
      time: time,
    );
  }

  Future<void> toggleReminders(bool enabled) async {
    if (enabled) {
      final bool basicPermissionGranted = await NotificationUtil.requestBasicPermission();
      final bool exactAlarmPermissionGranted = await NotificationUtil.requestExactAlarmPermission();
      // Ya no pedimos el de optimización de batería aquí, solo informamos en la UI.
      
      if (!basicPermissionGranted || !exactAlarmPermissionGranted) {
        return; 
      }
    }

    if (mounted) {
      state = state.copyWith(remindersEnabled: enabled);
    }

    if (enabled && state.reminderTime != null) {
      await _scheduleNotification(state.reminderTime!);
    } else {
      await NotificationUtil.cancelAllNotifications();
      if (!enabled && mounted) {
        state = state.copyWith(clearTime: true);
      }
    }
    await _saveSettings();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    if (mounted) {
      state = state.copyWith(reminderTime: time);
    }
    if (state.remindersEnabled) {
      await _scheduleNotification(time);
    }
    await _saveSettings();
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});