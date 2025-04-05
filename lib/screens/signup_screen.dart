import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SignUpScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(isDarkMode), // تحسين شكل الصورة
              const SizedBox(height: 25),
              _buildTextField(nameController, "الاسم الكامل", Icons.person, isDarkMode: isDarkMode),
              _buildTextField(phoneController, "رقم الهاتف", Icons.phone, isDarkMode: isDarkMode),
              _buildTextField(emailController, "البريد الإلكتروني", Icons.email, isDarkMode: isDarkMode),
              _buildTextField(passwordController, "كلمة المرور", Icons.lock, obscureText: true, isDarkMode: isDarkMode),
              _buildTextField(confirmPasswordController, "تأكيد كلمة المرور", Icons.lock, obscureText: true, isDarkMode: isDarkMode),
              const SizedBox(height: 25),
              Obx(() => authController.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: _buttonStyle(isDarkMode),
                onPressed: () {
                  authController.signUp(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    confirmPasswordController.text.trim(),
                    nameController.text.trim(),
                    phoneController.text.trim(),
                  );
                },
                child: const Text(
                  "تسجيل الحساب",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Get.offAllNamed("/login"),
                child: Text(
                  "لديك حساب بالفعل؟ تسجيل الدخول",
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue[300] : Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ تحسين شكل الصورة
  Widget _buildLogo(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // حواف مستديرة
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          "assets/logo.png",
          height: 90,
          width: 90,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
          prefixIcon: Icon(icon, color: isDarkMode ? Colors.blue[300] : Colors.blueAccent),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDarkMode ? Colors.blue[300]! : Colors.blueAccent),
          ),
        ),
        obscureText: obscureText,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }

  ButtonStyle _buttonStyle(bool isDarkMode) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blueAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
    );
  }
}