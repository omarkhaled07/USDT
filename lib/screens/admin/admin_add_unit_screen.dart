import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddUnitScreen extends StatefulWidget {
  const AdminAddUnitScreen({super.key});

  @override
  _AdminAddUnitScreenState createState() => _AdminAddUnitScreenState();
}

class _AdminAddUnitScreenState extends State<AdminAddUnitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();

  void _addUnit() async {
    if (_nameController.text.isEmpty ||
        _currencyController.text.isEmpty ||
        _minAmountController.text.isEmpty ||
        _exchangeRateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء جميع الحقول")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("payment_units").add({
        "name": _nameController.text,
        "currency": _currencyController.text,
        "min_amount": double.parse(_minAmountController.text),
        "exchange_rate": double.parse(_exchangeRateController.text),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت إضافة الوحدة بنجاح!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء إضافة الوحدة: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة وحدة تحويل"),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "اسم الوحدة",
                labelStyle: TextStyle(color: textColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _currencyController,
              decoration: InputDecoration(
                labelText: "العملة",
                labelStyle: TextStyle(color: textColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _minAmountController,
              decoration: InputDecoration(
                labelText: "أقل قيمة",
                labelStyle: TextStyle(color: textColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _exchangeRateController,
              decoration: InputDecoration(
                labelText: "سعر الصرف",
                labelStyle: TextStyle(color: textColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addUnit,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.teal[800] : Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("إضافة", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}