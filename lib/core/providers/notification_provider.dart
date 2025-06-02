// lib/core/providers/notification_provider.dart
import 'package:dental_ai_app/core/utils/notification_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _remindersEnabledKey = 'remindersEnabled';
const String _reminderHourKey = 'reminderHour';
const String _reminderMinuteKey = 'reminderMinute';

class NotificationSettings {
  final bool remindersEnabled;
  final TimeOfDay? reminderTime;

  NotificationSettings({this.remindersEnabled = false, this.reminderTime});

  NotificationSettings copyWith({
    bool? remindersEnabled,
    TimeOfDay? reminderTime,
    bool clearTime = false,
  }) {
    return NotificationSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: clearTime ? null : reminderTime ?? this.reminderTime,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool(_remindersEnabledKey) ?? false;
    TimeOfDay? time;
    final int? hour = prefs.getInt(_reminderHourKey);
    final int? minute = prefs.getInt(_reminderMinuteKey);

    if (hour != null && minute != null) {
      time = TimeOfDay(hour: hour, minute: minute);
    }
    
    if (mounted) {
      state = state.copyWith(remindersEnabled: enabled, reminderTime: time);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, state.remindersEnabled);
    if (state.reminderTime != null) {
      await prefs.setInt(_reminderHourKey, state.reminderTime!.hour);
      await prefs.setInt(_reminderMinuteKey, state.reminderTime!.minute);
    } else {
      await prefs.remove(_reminderHourKey);
      await prefs.remove(_reminderMinuteKey);
    }
  }

  Future<void> _scheduleNotification(TimeOfDay time) async {
    await NotificationUtil.scheduleDailyNotification(
      id: 0,
      title: 'Recordatorio de Higiene Bucal',
      body: '¡Es hora de cuidar tu sonrisa! No olvides cepillarte y usar hilo dental.',
      time: time,
    );
  }

  Future<void> _cancelAllNotifications() async {
    await NotificationUtil.cancelAllNotifications();
  }

  Future<void> toggleReminders(bool enabled) async {
    if (mounted) {
      state = state.copyWith(remindersEnabled: enabled);
    }
    if (enabled && state.reminderTime != null) {
      await _scheduleNotification(state.reminderTime!);
    } else {
      await _cancelAllNotifications();
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
