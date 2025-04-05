import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString("email") ?? "";
      passwordController.text = prefs.getString("password") ?? "";
    });
  }

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
              _buildLogo(),
              const SizedBox(height: 25),
              _buildTextField(emailController, "البريد الإلكتروني", Icons.email, isDarkMode: isDarkMode),
              _buildTextField(passwordController, "كلمة المرور", Icons.lock, obscureText: true, isDarkMode: isDarkMode),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => ResetPasswordScreen()),
                  child: Text(
                    "نسيت كلمة المرور؟",
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Obx(() => ElevatedButton(
                style: _buttonStyle(isDarkMode),
                onPressed: authController.isLoading.value ? null : _handleLogin,
                child: authController.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  "تسجيل الدخول",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )),

              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Get.off(() => SignUpScreen()),
                child: Text(
                  "ليس لديك حساب؟ سجل الآن",
                  style: TextStyle(
                    color: isDarkMode ? Colors.green[300] : Colors.green,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "خطأ",
        "يرجى إدخال البريد الإلكتروني وكلمة المرور",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Colors.white,
      );
      return;
    }

    authController.signIn(email, password);
  }

  Widget _buildLogo() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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