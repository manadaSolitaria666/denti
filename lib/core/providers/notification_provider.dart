// lib/core/providers/notification_provider.dart
import 'package:dental_ai_app/core/utils/notification_util.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _remindersEnabledKey = 'remindersEnabled';
const String _morningReminderHourKey = 'morningReminderHour';
const String _morningReminderMinuteKey = 'morningReminderMinute';
const String _afternoonReminderHourKey = 'afternoonReminderHour';
const String _afternoonReminderMinuteKey = 'afternoonReminderMinute';
const String _nightReminderHourKey = 'nightReminderHour';
const String _nightReminderMinuteKey = 'nightReminderMinute';

class NotificationSettings {
  final bool remindersEnabled;
  final TimeOfDay? morningReminder;
  final TimeOfDay? afternoonReminder;
  final TimeOfDay? nightReminder;
  
  NotificationSettings({this.remindersEnabled = false, this.morningReminder, this.afternoonReminder, this.nightReminder});

  NotificationSettings copyWith({bool? remindersEnabled, TimeOfDay? morningReminder, TimeOfDay? afternoonReminder, TimeOfDay? nightReminder, bool clearMorning = false, bool clearAfternoon = false, bool clearNight = false}) {
    return NotificationSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      morningReminder: clearMorning ? null : morningReminder ?? this.morningReminder,
      afternoonReminder: clearAfternoon ? null : afternoonReminder ?? this.afternoonReminder,
      nightReminder: clearNight ? null : nightReminder ?? this.nightReminder,
    );
  }
}

final notificationPermissionProvider = FutureProvider.autoDispose<PermissionStatus>((ref) => Permission.notification.status);
final exactAlarmPermissionProvider = FutureProvider.autoDispose<PermissionStatus>((ref) => Permission.scheduleExactAlarm.status);
final batteryOptimizationProvider = FutureProvider.autoDispose<PermissionStatus>((ref) => Permission.ignoreBatteryOptimizations.status);

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_remindersEnabledKey) ?? false;
    
    final morningHour = prefs.getInt(_morningReminderHourKey);
    final morningMinute = prefs.getInt(_morningReminderMinuteKey);
    final afternoonHour = prefs.getInt(_afternoonReminderHourKey);
    final afternoonMinute = prefs.getInt(_afternoonReminderMinuteKey);
    final nightHour = prefs.getInt(_nightReminderHourKey);
    final nightMinute = prefs.getInt(_nightReminderMinuteKey);
    
    if (mounted) {
      state = state.copyWith(
        remindersEnabled: enabled,
        morningReminder: (morningHour != null && morningMinute != null) ? TimeOfDay(hour: morningHour, minute: morningMinute) : null,
        afternoonReminder: (afternoonHour != null && afternoonMinute != null) ? TimeOfDay(hour: afternoonHour, minute: afternoonMinute) : null,
        nightReminder: (nightHour != null && nightMinute != null) ? TimeOfDay(hour: nightHour, minute: nightMinute) : null,
      );
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, state.remindersEnabled);
    
    if (state.morningReminder != null) {
      await prefs.setInt(_morningReminderHourKey, state.morningReminder!.hour);
      await prefs.setInt(_morningReminderMinuteKey, state.morningReminder!.minute);
    } else {
      await prefs.remove(_morningReminderHourKey);
      await prefs.remove(_morningReminderMinuteKey);
    }
    
    if (state.afternoonReminder != null) {
      await prefs.setInt(_afternoonReminderHourKey, state.afternoonReminder!.hour);
      await prefs.setInt(_afternoonReminderMinuteKey, state.afternoonReminder!.minute);
    } else {
      await prefs.remove(_afternoonReminderHourKey);
      await prefs.remove(_afternoonReminderMinuteKey);
    }

    if (state.nightReminder != null) {
      await prefs.setInt(_nightReminderHourKey, state.nightReminder!.hour);
      await prefs.setInt(_nightReminderMinuteKey, state.nightReminder!.minute);
    } else {
      await prefs.remove(_nightReminderHourKey);
      await prefs.remove(_nightReminderMinuteKey);
    }
  }

  Future<void> _scheduleAllEnabledReminders() async {
    await NotificationUtil.cancelAllNotifications();
    if (!state.remindersEnabled) return;

    if (state.morningReminder != null) {
      await NotificationUtil.scheduleDailyNotification(id: 0, title: "Recordatorio Matutino", body: "¡Es hora de tu cepillado de la mañana!", time: state.morningReminder!);
    }
    if (state.afternoonReminder != null) {
      await NotificationUtil.scheduleDailyNotification(id: 1, title: "Recordatorio Vespertino", body: "Recuerda tu higiene bucal después de comer.", time: state.afternoonReminder!);
    }
    if (state.nightReminder != null) {
      await NotificationUtil.scheduleDailyNotification(id: 2, title: "Recordatorio Nocturno", body: "¡No olvides cepillarte y usar hilo dental antes de dormir!", time: state.nightReminder!);
    }
  }

  Future<void> toggleReminders(bool enabled) async {
    if (enabled) {
      final permissionsGranted = await NotificationUtil.requestBasicPermission() && await NotificationUtil.requestExactAlarmPermission();
      if (!permissionsGranted) return; 
    }
    if (mounted) state = state.copyWith(remindersEnabled: enabled);
    await _scheduleAllEnabledReminders();
    await _saveSettings();
  }

  Future<void> setReminderTime(int type, TimeOfDay? time) async {
    if (mounted) {
      switch (type) {
        case 0: state = state.copyWith(morningReminder: time, clearMorning: time == null); break;
        case 1: state = state.copyWith(afternoonReminder: time, clearAfternoon: time == null); break;
        case 2: state = state.copyWith(nightReminder: time, clearNight: time == null); break;
      }
    }
    await _scheduleAllEnabledReminders();
    await _saveSettings();
  }

  Future<void> sendTestNotification() async {
    final bool permissionsGranted = await NotificationUtil.requestBasicPermission();
    if (permissionsGranted) {
      await NotificationUtil.showTestNotification();
    }
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});