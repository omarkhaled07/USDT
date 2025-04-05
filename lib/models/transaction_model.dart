import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String transactionId;
  final String userId;
  final String accountNumber;
  final String senderAccount;
  final String paymentMethod;
  final double sendAmount;
  final String sendType;
  final double receiveAmount;
  final String receiveType;
  final String status;
  final String imageUrl;
  final Timestamp timestamp;
  final String transactionNumber;

  TransactionModel({
    required this.id,
    required this.transactionId,
    required this.userId,
    required this.accountNumber,
    required this.senderAccount,
    required this.paymentMethod,
    required this.sendAmount,
    required this.sendType,
    required this.receiveAmount,
    required this.receiveType,
    required this.status,
    required this.imageUrl,
    required this.timestamp,
    required this.transactionNumber,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      transactionId: data['transactionId'] ?? '',
      userId: data['userId'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      senderAccount: data['senderAccount'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      sendAmount: (data['sendAmount'] as num).toDouble(),
      sendType: data['sendType'] ?? '',
      receiveAmount: (data['receiveAmount'] as num).toDouble(),
      receiveType: data['receiveType'] ?? '',
      status: data['status'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      transactionNumber: data["transactionId"] ?? "غير متوفر",

    );
  }
}
