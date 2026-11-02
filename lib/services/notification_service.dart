import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showPushNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Initialiser local notifications
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
    );
    await _plugin.initialize(settings);

    // Android 13+  demande POST_NOTIFICATIONS
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    // Demander permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Handler background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handler foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showPushNotification(message);
    });

    // Récupérer le token FCM
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  static Future<void> showPushNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'noche_push',
          'Notifications Noche',
          channelDescription: 'Notifications push Noche',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Noche <',
      message.notification?.body ?? '',
      details,
    );
  }

  static Future<void> showNewPostNotification({
    required String username,
    required String caption,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'noche_posts',
          'Nouveaux posts',
          channelDescription: 'Notifications pour les nouveaux posts',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '$username vient de publier <',
      caption.isNotEmpty ? caption : 'Nouveau post image',
      details,
    );
  }

  // Sauvegarder le token FCM dans Firestore
  static Future<void> saveTokenToFirestore(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }
}
