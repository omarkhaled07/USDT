import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usdt_express/screens/transaction_details_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String? _sendMethod;
  String? _receiveMethod;
  double? exchangeRate;
  double? minAmount;
  bool isLoading = false;

  final TextEditingController _sendAmountController = TextEditingController();
  final TextEditingController _receiveAmountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  final List<String> allMethods = [
    "أنستا باي (L.E)",
    "فودافون كاش (L.E)",
    "بابير (USD)",
    "ادفكاش (USD)",
    "(USD) بينانس باي",
    "Tron(TRC20)(USD)",
    "BNB smart chain (BEP20)(USD)",
    "Insta pay (USD)",
    "RedotoPay(USD)"
  ];

  final List<String> sendLE = ["أنستا باي (L.E)", "فودافون كاش (L.E)"];

  final List<String> sendUSD = [
    "(USD) بينانس باي",
    "Tron(TRC20)(USD)",
    "BNB smart chain (BEP20)(USD)",
  ];

  List<Map<String, dynamic>> userWallets = []; // قائمة المحافظ الخاصة بالمستخدم

  @override
  void initState() {
    super.initState();
    _fetchUserWallets(); // جلب محافظ المستخدم عند بدء التشغيل
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

  Future<void> fetchExchangeData() async {
    if (_sendMethod == null) return;

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection("currencies")
          .where("name", isEqualTo: _sendMethod)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        setState(() {
          exchangeRate = (doc["usdToEgp"] as num?)?.toDouble() ?? 53.0;
          minAmount = (doc["minTransfer"] as num?)?.toDouble() ?? 350.0;
        });
        _calculateReceiveAmount();
      } else {
        setState(() {
          exchangeRate = null;
          minAmount = null;
        });
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء جلب البيانات: $e");
    }
  }

  void _updateReceiveOptions(String selectedSendMethod) {
    setState(() {
      _sendMethod = selectedSendMethod;
      _receiveMethod = null;
    });
    fetchExchangeData();
  }

  void _calculateReceiveAmount() {
    if (_sendAmountController.text.isEmpty || exchangeRate == null) return;

    double sendAmount = double.tryParse(_sendAmountController.text) ?? 0;
    double receivedAmount;

    if (sendLE.contains(_sendMethod)) {
      receivedAmount = sendAmount / exchangeRate!;
    } else {
      receivedAmount = sendAmount * exchangeRate!;
    }

    setState(() {
      _receiveAmountController.text = receivedAmount.toStringAsFixed(2);
    });
  }

  void _addTransaction() async {
    double sendAmount = double.tryParse(_sendAmountController.text) ?? 0;
    double receiveAmount = double.tryParse(_receiveAmountController.text) ?? 0;

    if (_sendMethod == null ||
        _receiveMethod == null ||
        _sendAmountController.text.isEmpty ||
        _receiveAmountController.text.isEmpty ||
        _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ يرجى ملء جميع الحقول")),
      );
      return;
    }

    if (sendLE.contains(_sendMethod) && sendAmount < minAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ الحد الأدنى للتحويل هو $minAmount جنيه")),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionDetailsScreen(
            sendType: _sendMethod!,
            receiveType: _receiveMethod!,
            sendMethod: _sendMethod!,
            receiveMethod: _receiveMethod!,
            sendAmount: sendAmount,
            receiveAmount: receiveAmount,
            accountNumber: _accountNumberController.text,
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ خطأ أثناء إضافة المعاملة: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ حدث خطأ أثناء إضافة المعاملة")),
      );
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
                      _accountNumberController.text = wallet['walletNumber'] ?? '';
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
        title: const Text("نظام الدفع", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown("إرسال من", sendLE, _sendMethod, (value) {
                _updateReceiveOptions(value!);
              }, isDarkMode),
              if (_sendMethod != null) ...[
                const SizedBox(height: 10),
                Text(
                  "سعر الصرف: ${exchangeRate != null ? exchangeRate.toString() : 'جاري التحميل...'}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.blue[300] : Colors.blue),
                ),
                const SizedBox(height: 5),
                Text(
                  "أقل مبلغ للتحويل: ${minAmount != null ? minAmount.toString() : 'جاري التحميل...'}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.red[300] : Colors.red),
                ),
              ],
              const SizedBox(height: 10),
              _buildDropdown(
                "استقبال على",
                _sendMethod == null
                    ? []
                    : sendLE.contains(_sendMethod)
                    ? sendUSD
                    : sendLE,
                _receiveMethod,
                    (value) {
                  setState(() {
                    _receiveMethod = value;
                  });
                },
                isDarkMode,
              ),
              const SizedBox(height: 10),
              _buildTextField(_sendAmountController, "المبلغ المرسل", _calculateReceiveAmount, isDarkMode),
              const SizedBox(height: 10),
              _buildTextField(_receiveAmountController, "الكمية المستلمة", null, isDarkMode, true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_accountNumberController, "رقم الحساب", null, isDarkMode),
                  ),
                  IconButton(
                    icon: Icon(Icons.wallet, color: isDarkMode ? Colors.white : Colors.black),
                    iconSize: 30,
                    onPressed: _showWalletsBottomSheet,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("التالي", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, [Function()? onChanged, bool isDarkMode = false, bool readOnly = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          ),
          onChanged: onChanged != null ? (_) => onChanged() : null,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ],
    );
  }
}