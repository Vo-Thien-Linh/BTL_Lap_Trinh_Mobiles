import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_remote_data_source.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

typedef NotificationCallback = void Function(String? deepLink);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  NotificationCallback? _onTap;
  NotificationCallback? _onReceived;
  bool _initialized = false;

  static const AndroidNotificationChannel appointmentChannel = AndroidNotificationChannel(
    'hospital_appointment_channel',
    'Thông báo lịch khám',
    description: 'Xác nhận, hủy lịch, nhắc lịch khám và hướng dẫn chuẩn bị.',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel medicalChannel = AndroidNotificationChannel(
    'hospital_medical_channel',
    'Thông báo y tế',
    description: 'Kết quả khám, đơn thuốc, xét nghiệm, siêu âm và dịch vụ cận lâm sàng.',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
    'hospital_system_channel',
    'Thông báo hệ thống',
    description: 'Thông báo chung từ bệnh viện.',
    importance: Importance.defaultImportance,
  );

  Future<void> initialize({
    NotificationCallback? onTap,
    NotificationCallback? onReceived,
  }) async {
    if (_initialized) return;

    _onTap = onTap;
    _onReceived = onReceived;

    tz_data.initializeTimeZones();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleLocalTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(appointmentChannel);
    await androidPlugin?.createNotificationChannel(medicalChannel);
    await androidPlugin?.createNotificationChannel(systemChannel);
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      scheduleMicrotask(() => _handleMessageTap(initialMessage));
    }

    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('FCM token refreshed for ${user.uid}');
      }
    });

    _initialized = true;
  }

  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Cannot get FCM token: $e');
      return null;
    }
  }

  Future<void> registerCurrentUserDevice(
    NotificationRemoteDataSource remote, {
    String? role,
    String? email,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await getFCMToken();
    if (token == null || token.isEmpty) return;

    await remote.saveDeviceToken(
      userId: user.uid,
      token: token,
      role: role,
      email: email ?? user.email,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? deepLink,
    String channel = 'appointment',
    Map<String, dynamic> data = const {},
    int? notificationId,
  }) async {
    final androidChannel = _androidChannel(channel);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannel.id,
        androidChannel.name,
        channelDescription: androidChannel.description,
        importance: channel == 'system' ? Importance.defaultImportance : Importance.max,
        priority: channel == 'system' ? Priority.defaultPriority : Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'deepLink': deepLink,
      'data': data,
    });

    await _local.show(
      notificationId ?? _safeNotificationId('${title}_${body}_${DateTime.now().millisecondsSinceEpoch}'),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required String stableId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? deepLink,
    String channel = 'appointment',
    Map<String, dynamic> data = const {},
  }) async {
    if (!scheduledTime.isAfter(DateTime.now())) return;

    final androidChannel = _androidChannel(channel);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannel.id,
        androidChannel.name,
        channelDescription: androidChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'deepLink': deepLink,
      'data': data,
    });

    await _local.zonedSchedule(
      _safeNotificationId(stableId),
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleAppointmentLocalReminders({
    required String appointmentId,
    required DateTime appointmentTime,
    required String doctorName,
    required String departmentName,
    required String preparationText,
    String? deepLink,
  }) async {
    final data = {'appointmentId': appointmentId};

    await scheduleNotification(
      stableId: '${appointmentId}_reminder_24h',
      title: 'Nhắc lịch khám ngày mai',
      body: 'Bạn có lịch khám với BS. $doctorName vào ${_formatDateTime(appointmentTime)}.',
      scheduledTime: appointmentTime.subtract(const Duration(hours: 24)),
      deepLink: deepLink,
      channel: 'appointment',
      data: data,
    );

    await scheduleNotification(
      stableId: '${appointmentId}_preparation',
      title: 'Chuẩn bị trước khi khám',
      body: preparationText,
      scheduledTime: appointmentTime.subtract(const Duration(hours: 24)),
      deepLink: deepLink,
      channel: 'medical',
      data: data,
    );

    await scheduleNotification(
      stableId: '${appointmentId}_reminder_1h',
      title: 'Còn 1 giờ tới lịch khám',
      body: 'Vui lòng chuẩn bị giấy tờ và đến đúng giờ tại khoa $departmentName.',
      scheduledTime: appointmentTime.subtract(const Duration(hours: 1)),
      deepLink: deepLink,
      channel: 'appointment',
      data: data,
    );
  }

  Future<void> cancelAppointmentLocalReminders(String appointmentId) async {
    await _local.cancel(_safeNotificationId('${appointmentId}_reminder_24h'));
    await _local.cancel(_safeNotificationId('${appointmentId}_preparation'));
    await _local.cancel(_safeNotificationId('${appointmentId}_reminder_1h'));
  }

  Future<void> cancelAllNotifications() => _local.cancelAll();

  void _handleLocalTap(NotificationResponse response) {
    final deepLink = _extractDeepLink(response.payload);
    _onTap?.call(deepLink);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final deepLink = message.data['deepLink']?.toString();
    _onReceived?.call(deepLink);

    final title = message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title != null && body != null) {
      showLocalNotification(
        title: title,
        body: body,
        deepLink: deepLink,
        channel: message.data['category']?.toString() ?? 'system',
        data: message.data,
      );
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    _onTap?.call(message.data['deepLink']?.toString());
  }

  AndroidNotificationChannel _androidChannel(String channel) {
    switch (channel) {
      case 'medical':
      case 'service':
        return medicalChannel;
      case 'system':
        return systemChannel;
      case 'appointment':
      default:
        return appointmentChannel;
    }
  }

  String? _extractDeepLink(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return data['deepLink']?.toString();
    } catch (_) {
      return payload;
    }
  }

  int _safeNotificationId(String input) {
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return max(1, hash);
  }

  String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} lúc ${value.hour}:$minute';
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('Local notification tapped in background: ${response.payload}');
}
