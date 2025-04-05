import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> savePlayerIDToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // الحصول على playerID من OneSignal
  var pushSubscription = await OneSignal.User.pushSubscription;
  if (pushSubscription == null || pushSubscription.id == null) return;

  String playerID = pushSubscription.id!;

  // حفظ playerID في Firestore
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'playerID': playerID,
  });

  print("✅ تم حفظ playerID: $playerID");
}