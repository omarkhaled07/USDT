import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/custom_buttom.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();

  Future<void> _resetPassword() async {
    try {
      String email = emailController.text.trim();

      if (email.isEmpty) {
        Get.snackbar(
          "Error",
          "Please enter your email",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        "Success",
        "Password reset email sent to $email",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      print("✅ Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Error: ${e.code}");
      String errorMessage = "Failed to send email.";

      if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address.";
      } else if (e.code == 'user-not-found') {
        errorMessage = "No account found for this email.";
      }

      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      print("❌ Unexpected Error: $e");
      Get.snackbar(
        "Error",
        "Something went wrong. Try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Enter Your Email", emailController, isDarkMode),
            const SizedBox(height: 20),
            CustomButton(
              onPress: _resetPassword,
              text: "Send Reset Link",
              backgroundColor: isDarkMode ? Colors.blue[800]! : Colors.blue,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDarkMode ? Colors.blue[300]! : Colors.blue),
          ),
        ),
      ),
    );
  }
}