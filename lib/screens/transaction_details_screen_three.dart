import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionDetailsScreenThree extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreenThree({super.key, required this.transaction});

  @override
  _TransactionDetailsScreenThreeState createState() => _TransactionDetailsScreenThreeState();
}

class _TransactionDetailsScreenThreeState extends State<TransactionDetailsScreenThree> {
  bool _isUpdating = false;
  String _currentStatus = "";

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.transaction.status;
  }

  /// تحديث حالة العملية إلى "ملغية" في حال كانت "معلقة"
  Future<void> _cancelTransaction() async {
    if (_currentStatus != "معلقة") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("لا يمكن إلغاء العملية في هذه الحالة"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transaction.id)
          .update({'status': "ملغية"});

      setState(() {
        _currentStatus = "ملغية";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم إلغاء العملية"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("حدث خطأ أثناء إلغاء العملية"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل العملية"),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionInfoCard("نوع التحويل", widget.transaction.sendType, isDarkMode),
              _buildTransactionInfoCard("نوع الاستلام", widget.transaction.receiveType, isDarkMode),
              _buildTransactionInfoCard("رقم الحساب", widget.transaction.accountNumber, isDarkMode),
              _buildTransactionInfoCard("المبلغ المرسل", "${widget.transaction.sendAmount}", isDarkMode),
              _buildTransactionInfoCard("المبلغ المستلم", "${widget.transaction.receiveAmount}", isDarkMode),
              _buildTransactionInfoCard("رقم العملية", widget.transaction.transactionNumber, isDarkMode),
              _buildTransactionInfoCard("الحالة", _currentStatus, isDarkMode),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isUpdating ? null : _cancelTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.red[800] : Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("إلغاء العملية", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تصميم عنصر معلومات العملية
  Widget _buildTransactionInfoCard(String title, String value, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }
}