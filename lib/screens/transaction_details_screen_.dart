import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // استيراد مكتبة Clipboard
import '../models/transaction_model.dart';

class TransactionDetailsScreenTwo extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreenTwo({super.key, required this.transaction});

  @override
  _TransactionDetailsScreenTwoState createState() => _TransactionDetailsScreenTwoState();
}

class _TransactionDetailsScreenTwoState extends State<TransactionDetailsScreenTwo> {
  bool _isUpdating = false;
  String _currentStatus = "";

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.transaction.status;
  }

  /// تحديث حالة العملية في Firebase
  Future<void> _updateTransactionStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transaction.id)
          .update({'status': newStatus});

      setState(() {
        _currentStatus = newStatus;
      });

      Fluttertoast.showToast(msg: "تم تحديث حالة العملية إلى $newStatus");
    } catch (error) {
      Fluttertoast.showToast(msg: "حدث خطأ أثناء تحديث الحالة");
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  /// تحميل الصورة إلى الجهاز
  Future<void> _downloadImage() async {
    if (widget.transaction.imageUrl.isEmpty) {
      Fluttertoast.showToast(msg: "لا يوجد صورة للتنزيل");
      return;
    }

    // طلب الأذونات
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final taskId = await FlutterDownloader.enqueue(
          url: widget.transaction.imageUrl,
          savedDir: '/storage/emulated/0/Download', // مكان الحفظ
          showNotification: true,
          openFileFromNotification: true,
        );
        Fluttertoast.showToast(msg: "تم تنزيل الصورة بنجاح");
      } catch (error) {
        Fluttertoast.showToast(msg: "فشل تحميل الصورة: $error");
      }
    } else {
      Fluttertoast.showToast(msg: "أذونات التخزين غير مفعلة");
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

              widget.transaction.imageUrl.isNotEmpty
                  ? Column(
                children: [
                  Image.network(widget.transaction.imageUrl, height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _downloadImage,
                    icon: const Icon(Icons.download),
                    label: const Text("تنزيل الصورة"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
                    ),
                  ),
                ],
              )
                  : Center(
                child: Text(
                  "لم يتم رفع سكرين",
                  style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _updateTransactionStatus("مؤكدة"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("تأكيد العملية", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _updateTransactionStatus("مرفوضة"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.red[800] : Colors.red,
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("رفض العملية", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : () => _updateTransactionStatus("جارى التنفيذ"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.orange[800] : Colors.orangeAccent,
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("جارى التنفيذ", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تصميم عنصر معلومات العملية مع إضافة النسخ
  Widget _buildTransactionInfoCard(String title, String value, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        Fluttertoast.showToast(msg: "تم نسخ $title: $value");
      },
      child: Card(
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
      ),
    );
  }
}