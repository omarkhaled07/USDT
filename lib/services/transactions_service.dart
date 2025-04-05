import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📌 **جلب المعاملات للمستخدم الحالي**
  Stream<QuerySnapshot> getUserTransactions() {
    return _firestore
        .collection("transactions")
        .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// 📌 **جلب جميع المعاملات**
  Stream<QuerySnapshot> getAllTransactions() {
    return _firestore.collection("transactions").snapshots();
  }
}