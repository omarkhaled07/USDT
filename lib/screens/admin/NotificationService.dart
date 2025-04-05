import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String oneSignalAppId = "023b1172-b776-4853-a6c3-8465a425d5d2";
  static const String oneSignalRestApiKey = "os_v2_app_ai5rc4vxozefhjwdqrs2ijov2liz6ymnagwuryfjx6euprvgoagdh2j4mgxc3dwlh64lpdpj5e6rtgpaqsb6kuz37tgmz6t5jqvixji";

  static Future<void> sendNotificationToAdmin(String messageBody) async {
    try {
      // جلب بيانات الأدمن من Firestore
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminSnapshot.docs.isEmpty) {
        print("⚠️ لا يوجد أدمن في قاعدة البيانات!");
        return;
      }

      String? adminPlayerID = adminSnapshot.docs[0].get('playerID');
      if (adminPlayerID == null) {
        print("⚠️ playerID الخاص بالأدمن غير موجود!");
        return;
      }

      print("🆔 playerID الخاص بالأدمن: $adminPlayerID");

      var headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Basic $oneSignalRestApiKey",
      };

      var body = jsonEncode({
        "app_id": oneSignalAppId,
        "include_player_ids": [adminPlayerID],
        "headings": {"en": "إشعار جديد"},
        "contents": {"en": messageBody},
      });

      var response = await http.post(
        Uri.parse("https://onesignal.com/api/v1/notifications"),
        headers: headers,
        body: body,
      );

      print("📩 OneSignal Response: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ تم إرسال الإشعار بنجاح!");
      } else {
        print("❌ فشل إرسال الإشعار: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ حدث خطأ أثناء إرسال الإشعار: $e");
    }
  }
}