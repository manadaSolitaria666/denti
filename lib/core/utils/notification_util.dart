// lib/core/utils/notification_util.dart
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_native_timezone/flutter_native_timezone.dart'; // Opcional para mayor precisión de zona horaria

class NotificationUtil {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // Opcional: Configurar la zona horaria local del dispositivo para mayor precisión
    // try {
    //   final String? localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    //   if (localTimeZone != null && localTimeZone.isNotEmpty) {
    //     tz.setLocalLocation(tz.getLocation(localTimeZone));
    //   }
    // } catch (e) {
    //   if (kDebugMode) {
    //     print('Error obteniendo la zona horaria local: $e');
    //   }
    // }


    // Asegúrate de tener un ícono llamado 'app_icon.png' (o el nombre que uses)
    // en android/app/src/main/res/drawable (o mipmap)
    // Por ejemplo, @mipmap/ic_launcher es común.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); 

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Para iOS < 10
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse, // Para manejar notificaciones en background
    );

    // Solicitar permisos en iOS explícitamente si es necesario (para iOS >= 10)
    // FlutterLocalNotificationsPlugin >=9.0.0 maneja esto en initialize
    // pero para versiones anteriores o para más control:
    // await requestIOSPermissions();
  }

  // Manejador cuando se toca una notificación y la app está en primer plano o segundo plano (no terminada)
  static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      if (kDebugMode) {
        print('Notification payload: $payload');
      }
      // Aquí puedes manejar la navegación o acciones basadas en el payload
      // Ejemplo: MyApp.navigatorKey.currentState?.pushNamed('/details', arguments: payload);
    }
  }
  
  // Manejador para cuando se toca una notificación y la app estaba terminada (solo Android por ahora con esta firma)
  @pragma('vm:entry-point') // Necesario para que funcione en background en Flutter >=3.3.0
  static void onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
    // Asegúrate de que este manejador sea lo más ligero posible.
    // No intentes actualizar UI directamente aquí.
    // Puedes guardar datos o usar otras formas de comunicación si es necesario.
     final String? payload = notificationResponse.payload;
    if (payload != null) {
      if (kDebugMode) {
        print('Background Notification payload: $payload');
      }
    }
  }


  // static Future<void> requestIOSPermissions() async {
  //   await _notificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //           IOSFlutterLocalNotificationsPlugin>()
  //       ?.requestPermissions(
  //         alert: true,
  //         badge: true,
  //         sound: true,
  //       );
  // }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_id_1', // ID único del canal
          'Recordatorios Diarios de Higiene',
          channelDescription: 'Canal para recordatorios diarios de higiene bucal.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher', // Reemplaza con tu ícono
          // sound: RawResourceAndroidNotificationSound('custom_sound'), // Si tienes un sonido personalizado
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // sound: 'default', // o nombre del archivo de sonido personalizado
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payload ?? 'daily_reminder_payload', // Un payload por defecto
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente a la misma hora
      );
      if (kDebugMode) {
        print('Notificación programada para: $scheduledDate con ID: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al programar notificación: $e');
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    if (kDebugMode) {
      print('Notificación cancelada con ID: $id');
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('Todas las notificaciones canceladas.');
    }
  }
}
