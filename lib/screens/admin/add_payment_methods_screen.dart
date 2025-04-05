import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_new_payment_method_screen.dart';
import 'edit_payment_method_screen.dart'; // تأكد من إنشاء هذه الشاشة

class AddPaymentMethodsScreen extends StatefulWidget {
  const AddPaymentMethodsScreen({super.key});

  @override
  _AddPaymentMethodsScreenState createState() => _AddPaymentMethodsScreenState();
}

class _AddPaymentMethodsScreenState extends State<AddPaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة وسائل الدفع"),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNewPaymentMethodScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('paymentMethods')
            .doc('methods')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "لا توجد بيانات متاحة.",
                style: TextStyle(fontSize: 18, color: textColor),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final methods = List<String>.from(data['methods'] ?? []);
          final accounts = data['accounts'] as Map<String, dynamic>? ?? {};

          final accountLists = accounts.map<String, List<String>>((key, value) {
            if (value is List) {
              return MapEntry(key, List<String>.from(value));
            } else {
              return MapEntry(key, []);
            }
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              final accountList = accountLists[method] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                child: ListTile(
                  title: Text(
                    method,
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: accountList.map((account) {
                      return Text(
                        account,
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      );
                    }).toList(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPaymentMethodScreen(
                                method: method,
                                accounts: accountList,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePaymentMethod(method),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deletePaymentMethod(String method) async {
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

      methods.remove(method);
      accounts.remove(method);

      await docRef.update({
        'methods': methods,
        'accounts': accounts,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم حذف $method بنجاح!")),
      );
    }
  }
}