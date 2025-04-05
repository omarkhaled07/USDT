import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../login_screen.dart';
import 'add_payment_methods_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_currencies_screen.dart';
import 'notifications_screen.dart'; // شاشة عرض الإشعارات
import 'notification_icon.dart'; // استيراد NotificationIcon

// Controller لإدارة الوضع (اللايت/الدارك)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  void toggleTheme() async {
    isDarkMode.toggle();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _saveTheme(isDarkMode.value);
  }

  void _saveTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", isDark);
  }

  void loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool("isDarkMode") ?? false;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final isDarkMode = themeController.isDarkMode.value;
          final textColor = isDarkMode ? Colors.white : Colors.black;
          return Text(
            "لوحة التحكم",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          );
        }),
        centerTitle: true,
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        actions: [
          Obx(() {
            final isDarkMode = themeController.isDarkMode.value;
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: textColor,
              ),
              onPressed: () {
                themeController.toggleTheme();
              },
            );
          }),
          NotificationIcon(),
          Obx(() {
            final isDarkMode = themeController.isDarkMode.value;
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return IconButton(
              icon: Icon(Icons.logout, color: textColor),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => LoginScreen());
              },
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(constraints.maxWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                _buildLogo(),
                SizedBox(height: constraints.maxHeight * 0.1),
                _buildAdminButton(
                  context,
                  "إدارة العملات",
                  Icons.monetization_on,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCurrenciesScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildAdminButton(
                  context,
                  "إدارة الطلبات",
                  Icons.list_alt,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOrdersScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildAdminButton(
                  context,
                  "الدعم الفني",
                  Icons.support_agent,
                  Colors.red,
                  () {
                    // لم يتم التنفيذ بعد
                  },
                ),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildAdminButton(
                  context,
                  "إضافة وسائل الدفع",
                  Icons.add,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPaymentMethodsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Obx(() {
      final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
      final buttonTextColor = isDarkMode ? Colors.black : Colors.white;

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: buttonTextColor, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: buttonTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          "assets/logo.png",
          height: 120,
          width: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
