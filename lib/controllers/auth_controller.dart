import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/admin/player_id.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var isLoading = false.obs;

  Future<void> signIn(String email, String password) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // ✅ حفظ بيانات المستخدم في SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("uid", uid);
      prefs.setString("email", email);
      prefs.setString("password", password);

      // ✅ تحديد الوجهة بناءً على الدور
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      String role = "user";
      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        await savePlayerIDToFirestore();
        role = (userDoc.data() as Map<String, dynamic>)["role"] ?? "user";
      }

      if (role == "admin") {
        Get.offAllNamed("/admin_dashboard");
      } else {
        Get.offAllNamed("/home");
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الدخول: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();

    // ✅ حذف بيانات المستخدم من SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Get.offAllNamed("/login");
  }

  Future<void> signUp(String email, String password, String confirmPassword, String name, String phone) async {
    try {
      isLoading(true);

      if (password != confirmPassword) {
        Get.snackbar("خطأ", "كلمات المرور غير متطابقة!", snackPosition: SnackPosition.BOTTOM);
        isLoading(false);
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔹 **إضافة دور افتراضي "user" للمستخدم الجديد**
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": name,
        "phone": phone,
        "email": email,
        "uid": userCredential.user!.uid,
        "role": "user", // الدور الافتراضي هو "user"
      });

      await userCredential.user!.sendEmailVerification();
      Get.snackbar("نجاح", "تم إرسال كود التحقق إلى بريدك الإلكتروني", snackPosition: SnackPosition.BOTTOM);

      Get.offAllNamed("/login");
    } catch (e) {
      Get.snackbar("خطأ", "فشل تسجيل الحساب: ${e.toString()}", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }
}
