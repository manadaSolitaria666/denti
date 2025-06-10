// lib/core/utils/notification_util.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationUtil {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'dental_ai_daily_reminders';
  static const String _channelName = 'Recordatorios de Higiene';
  static const String _channelDescription = 'Canal para recordatorios diarios de higiene bucal.';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
  }

  static Future<bool> requestBasicPermission() async {
    PermissionStatus status = await Permission.notification.status;
    if (kDebugMode) print('Estado del permiso de notificación: $status');

    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    
    return status.isGranted;
  }

  static Future<bool> requestExactAlarmPermission() async {
    PermissionStatus status = await Permission.scheduleExactAlarm.status;
    if (kDebugMode) print('Estado del permiso de alarma exacta: $status');

    if (status.isDenied) {
        status = await Permission.scheduleExactAlarm.request();
    }
    
    return status.isGranted;
  }
  
  static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && kDebugMode) {
        print('Notification payload: $payload');
    }
  }
  
  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && kDebugMode) {
      print('Background Notification payload: $payload');
    }
  }

  static Future<void> showTestNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _notificationsPlugin.show(
      99, // Un ID único para la notificación de prueba
      'Prueba de Notificación', 
      'Si puedes ver esto, ¡las notificaciones funcionan!', 
      notificationDetails,
      payload: 'test_payload'
    );
    if (kDebugMode) print('Mostrando notificación de prueba.');
  }


  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final location = tz.getLocation('America/Mexico_City');
      final tz.TZDateTime now = tz.TZDateTime.now(location);
      
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payload ?? 'daily_reminder_payload_$id',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      if (kDebugMode) {
        print('Notificación programada para (CDMX Time): $scheduledDate con ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al programar notificación con ID $id: $e');
      }
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('Todas las notificaciones canceladas.');
    }
  }
}