import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:usdt_express/screens/SplashScreen.dart';
import 'package:usdt_express/screens/admin/admin_dashboard_screen.dart';
import 'package:usdt_express/theme/theme_notifier.dart';
import 'firebase_options.dart';
import 'screens/transactions_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة Firebase Messaging
  await _setupFirebaseMessaging();

  // تهيئة OneSignal
  await _initializeOneSignal();

  // تحميل حالة الثيم المحفوظة
  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();
  final themeController = Get.put(ThemeController());
  themeController.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeNotifier,
      child: const MyApp(),
    ),
  );
}

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

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print("🔔 إشعار في الخلفية: ${message.notification?.title}");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _initializeOneSignal() async {
  // قم بتعيين App ID الخاص بك من لوحة تحكم OneSignal
  await OneSignal.Debug.setLogLevel(OSLogLevel.verbose); // تفعيل وضع التصحيح
  OneSignal.initialize("023b1172-b776-4853-a6c3-8465a425d5d2");

  // طلب إذن الإشعارات
  await OneSignal.Notifications.requestPermission(true);

  // التعامل مع النقر على الإشعارات
  OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
    print("تم النقر على الإشعار: ${event.notification.body}");
    // يمكنك إضافة تنقل أو أي منطق آخر هنا
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      return doc.exists ? (doc.data()?["role"] ?? "user") : "user";
    } catch (e) {
      print("Error fetching user role: $e");
      return "guest";
    }
  }

  Future<String> _getInitialRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString("uid");

    if (uid != null) {
      String role = await _getUserRole(uid);
      return (role == "admin") ? "/admin_dashboard" : "/home";
    }

    return "/login";
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'USDT Express',
          initialRoute: "/splash",
          theme: ThemeData.light(), // الثيم الفاتح
          darkTheme: ThemeData.dark(), // الثيم الداكن
          themeMode: themeNotifier.themeMode, // الثيم الحالي
          getPages: [
            GetPage(name: "/splash", page: () => const SplashScreen()),
            GetPage(name: "/login", page: () => LoginScreen()),
            GetPage(name: "/home", page: () => TransactionsScreen()),
            GetPage(name: "/admin_dashboard", page: () => AdminDashboardScreen()),
          ],
        );
      },
    );
  }
}