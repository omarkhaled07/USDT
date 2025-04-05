import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddNewPaymentMethodScreen extends StatefulWidget {
  const AddNewPaymentMethodScreen({super.key});

  @override
  _AddNewPaymentMethodScreenState createState() => _AddNewPaymentMethodScreenState();
}

class _AddNewPaymentMethodScreenState extends State<AddNewPaymentMethodScreen> {
  final TextEditingController _methodsController = TextEditingController();
  final TextEditingController _accountsController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة وسيلة دفع جديدة"),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.blue,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _methodsController,
              decoration: InputDecoration(
                labelText: "وسيلة الدفع",
                labelStyle: TextStyle(color: textColor),
                hintText: "مثال: Vodafone Cash",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _accountsController,
              decoration: InputDecoration(
                labelText: "الحسابات (مفصولة بفاصلة)",
                labelStyle: TextStyle(color: textColor),
                hintText: "مثال: 01011095485, 01022427109",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePaymentMethods,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("حفظ البيانات"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePaymentMethods() async {
    if (_methodsController.text.isEmpty || _accountsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يجب ملء جميع الحقول!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newMethod = _methodsController.text.trim();
      final newAccounts = _accountsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty) // تجاهل القيم الفارغة
          .toList();

      if (newAccounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يجب إدخال حسابات صالحة!")),
        );
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('paymentMethods').doc('methods');
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final methods = List<String>.from(data['methods'] ?? []);
        final accounts = Map<String, List<String>>.from(
          (data['accounts'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );

        // التحقق من عدم وجود وسيلة دفع مكررة
        if (methods.contains(newMethod)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("وسيلة الدفع موجودة بالفعل!")),
          );
          return;
        }

        methods.add(newMethod);
        accounts[newMethod] = newAccounts;

        await docRef.update({
          'methods': methods,
          'accounts': accounts,
        });
      } else {
        await docRef.set({
          'methods': [newMethod],
          'accounts': {newMethod: newAccounts},
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ البيانات بنجاح!")),
      );

      Navigator.pop(context); // العودة إلى الشاشة السابقة
      _methodsController.clear();
      _accountsController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}