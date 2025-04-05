import 'package:firebase_messaging/firebase_messaging.dart';


Future<void> _setupFirebaseMessaging() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب إذن الإشعارات
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ تم تفعيل الإشعارات");
  } else {
    print("❌ لم يتم تفعيل الإشعارات");
  }

  // التعامل مع الإشعارات عند فتح التطبيق
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📨 تم استقبال إشعار: ${message.notification?.title}");
  });
}
