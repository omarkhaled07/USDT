import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPaymentMethodScreen extends StatefulWidget {
  final String method;
  final List<String> accounts;

  const EditPaymentMethodScreen({super.key, required this.method, required this.accounts});

  @override
  _EditPaymentMethodScreenState createState() => _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final TextEditingController _accountsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _accountsController.text = widget.accounts.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل وسيلة الدفع"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.method,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _accountsController,
              decoration: const InputDecoration(
                labelText: "الحسابات (مفصولة بفاصلة)",
                hintText: "مثال: 01011095485, 01022427109",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _updatePaymentMethod,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("حفظ التعديلات"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePaymentMethod() async {
    setState(() => _isSaving = true);

    try {
      final newAccounts = _accountsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
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
        final accounts = Map<String, List<String>>.from(
          (data['accounts'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );

        accounts[widget.method] = newAccounts;

            await docRef.update({
        'accounts': accounts,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث البيانات بنجاح!")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}