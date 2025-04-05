import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin/NotificationService.dart';
import 'admin/notifications_screen.dart';
import 'transactions_screen.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String sendType;
  final String receiveType;
  final String sendMethod;
  final String receiveMethod;
  final double sendAmount;
  final double receiveAmount;
  final String accountNumber;

  const TransactionDetailsScreen({
    super.key,
    required this.sendType,
    required this.receiveType,
    required this.sendMethod,
    required this.receiveMethod,
    required this.sendAmount,
    required this.receiveAmount,
    required this.accountNumber,
  });

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final TextEditingController _senderAccountController = TextEditingController();
  File? _selectedImage;
  bool _isProcessing = false;
  String? _selectedMethod;
  late String transactionId;

  List<String> paymentMethods = []; // قائمة وسائل الدفع
  Map<String, List<String>> paymentAccounts = {}; // الحسابات المرتبطة بكل وسيلة دفع
  List<Map<String, dynamic>> userWallets = []; // تعريف المتغير userWallets

  @override
  void initState() {
    super.initState();
    transactionId = _generateTransactionId();
    _fetchUserWallets(); // جلب محافظ المستخدم
    _fetchPaymentMethods(); // جلب وسائل الدفع من Firestore
  }

  String _generateTransactionId() {
    final random = Random();
    return List.generate(9, (index) => random.nextInt(10)).join();
  }

  Future<void> _fetchUserWallets() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userWallets = List<Map<String, dynamic>>.from(userDoc['wallets'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء جلب محافظ المستخدم: $e");
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      DocumentSnapshot paymentMethodsDoc = await FirebaseFirestore.instance
          .collection('paymentMethods')
          .doc('methods')
          .get();

      if (paymentMethodsDoc.exists) {
        final data = paymentMethodsDoc.data() as Map<String, dynamic>;

        // جلب قائمة وسائل الدفع وتحويلها إلى List<String>
        final methods = List<String>.from(data['methods'] ?? []);

        // جلب الحسابات كـ Map<String, List<String>>
        final accounts = Map<String, List<String>>.from(
            (data['accounts'] as Map<String, dynamic>).map(
                  (key, value) => MapEntry(key, List<String>.from(value)),)
            );

            debugPrint("Methods: $methods"); // طباعة وسائل الدفع
        debugPrint("Accounts: $accounts"); // طباعة الحسابات

        setState(() {
          paymentMethods = methods; // تخزين وسائل الدفع
          paymentAccounts = accounts; // تخزين الحسابات
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء جلب وسائل الدفع: $e");
    }
  }
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> saveTransaction() async {
    if (_isProcessing) return;

    if (_selectedMethod == null || _senderAccountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يجب اختيار وسيلة التحويل وإدخال الحساب الذي تم التحويل منه!")),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد العملية"),
        content: const Text("هل أنت متأكد من حفظ العملية؟"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("إلغاء")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("تأكيد")),
        ],
      ),
    );

    if (!confirm) return;

    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToImgBB(_selectedImage!);
    }

    await FirebaseFirestore.instance.collection('transactions').add({
      'transactionId': transactionId,
      'sendType': widget.sendType,
      'sendAmount': widget.sendAmount,
      'receiveType': widget.receiveType,
      'receiveAmount': widget.receiveAmount,
      'status': "معلقة",
      'accountNumber': widget.accountNumber,
      'paymentMethod': _selectedMethod,
      'senderAccount': _senderAccountController.text,
      'userId': user.uid,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'معاملة جديدة',
      'transactionId': transactionId,
      'body': 'تمت إضافة معاملة جديدة بقيمة ${widget.sendAmount} ${widget.sendType}',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await NotificationService.sendNotificationToAdmin('تمت إضافة معاملة جديدة بقيمة ${widget.sendAmount} ${widget.sendType}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حفظ العملية بنجاح!")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TransactionsScreen()),
    );
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    const String apiKey = "8b76fe22c80007a299747564ceed8f8a";
    var request = http.MultipartRequest("POST", Uri.parse("https://api.imgbb.com/1/upload"));
    request.fields["key"] = apiKey;
    request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonResponse = jsonDecode(responseData);

    if (jsonResponse["success"]) {
      return jsonResponse["data"]["url"];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل رفع الصورة! حاول مرة أخرى")),
      );
      return null;
    }
  }

  void _showWalletsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "اختر محفظة",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (userWallets.isEmpty)
                const Text("لا توجد محافظ متاحة."),
              ...userWallets.map((wallet) {
                return ListTile(
                  title: Text(wallet['walletType'] ?? 'نوع المحفظة غير متوفر'),
                  subtitle: Text(wallet['walletNumber'] ?? 'رقم المحفظة غير متوفر'),
                  onTap: () {
                    setState(() {
                      _senderAccountController.text = wallet['walletNumber'] ?? '';
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("بيانات العملية"),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blueAccent,
              ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionInfoCard("رقم العملية", transactionId, isDarkMode),
              const SizedBox(height: 15),
              _buildTransactionInfoCard("إرسال", "${widget.sendAmount} ${widget.sendType}", isDarkMode),
              _buildTransactionInfoCard("استقبال", "${widget.receiveAmount} ${widget.receiveType}", isDarkMode),
              const SizedBox(height: 20),
              _buildSectionTitle("اختر وسيلة التحويل", isDarkMode),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                items: paymentMethods
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMethod = value),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
              ),
              if (_selectedMethod != null) ...[
                const SizedBox(height: 15),
                _buildSectionTitle("أرسل المبلغ إلى", isDarkMode),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: paymentAccounts[_selectedMethod!]!
                        .map((number) => GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: number)); // نسخ الرقم
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم نسخ الرقم إلى الحافظة")),
                        );
                      },
                      child: Chip(
                        label: Text(number),
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildSectionTitle("رقم الحساب الذي حولت منه", isDarkMode),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _senderAccountController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "أدخل الرقم أو الحساب الذي حولت منه",
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.wallet, color: isDarkMode ? Colors.white : Colors.black),
                    iconSize: 30, // زيادة حجم الأيقونة
                    onPressed: _showWalletsBottomSheet,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("رفع صورة التحويل", isDarkMode),
              _buildUploadImageButton(isDarkMode),
              const SizedBox(height: 20),
              _buildNotice(isDarkMode),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : saveTransaction,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "تأكيد العملية",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildTransactionInfoCard(String title, String value, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
            Text(value, style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.blue[300] : Colors.blueAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadImageButton(bool isDarkMode) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blueAccent,
          ),
          child: const Text("اختر صورة التحويل"),
        ),
        if (_selectedImage != null) Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
      ],
    );
  }

  Widget _buildNotice(bool isDarkMode) {
    // جلب البيانات من Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('workingTimes').doc('sORrx5zxVIpnPhRJiSmU').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // عرض مؤشر تحميل أثناء جلب البيانات
        }
        if (snapshot.hasError) {
          return Text('حدث خطأ أثناء جلب البيانات'); // عرض رسالة خطأ إذا فشل جلب البيانات
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('لا توجد بيانات متاحة'); // عرض رسالة إذا لم توجد بيانات
        }

        // استخراج البيانات من المستند
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String workTime = data['workTime'] ?? '⏳ العمل من 9 صباحًا حتى 12 منتصف الليل';
        String order = data['order'] ?? '⏳ مدة تنفيذ الطلب من 5 إلى 15 دقيقة.';

        // عرض البيانات في الويدجت
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$workTime\n$order\n❗ الرجاء عدم التواصل مع الدعم قبل مرور الوقت المحدد.",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
        );
      },
    );
  }
}