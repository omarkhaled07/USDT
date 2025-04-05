import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> signUpWithEmailVerification(String email, String password, String name, String phone) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print("Error in signUpWithEmailVerification: $e");
      return false;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: "user-not-found",
          message: "المستخدم غير موجود",
        );
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        throw FirebaseAuthException(
          code: "email-not-verified",
          message: "يجب عليك تأكيد بريدك الإلكتروني قبل تسجيل الدخول",
        );
      }

      return user;
    } catch (e) {
      print("Error in signIn: ${e.toString()}");
      return null;
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get userStream {
    return _auth.authStateChanges();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Error in resetPassword: $e");
      return false;
    }
  }

}
