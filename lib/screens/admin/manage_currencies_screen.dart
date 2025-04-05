import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ManageCurrenciesScreen extends StatelessWidget {
  final CollectionReference currenciesRef = FirebaseFirestore.instance.collection("currencies");

  ManageCurrenciesScreen({super.key});

  /// **عرض شاشة تعديل العملة كـ BottomSheet**
  void _editCurrency(BuildContext context, String docId, Map<String, dynamic> currency) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;

    TextEditingController rateController = TextEditingController(text: currency["rate"].toString());
    TextEditingController minTransferController = TextEditingController(text: currency["minTransfer"].toString());
    TextEditingController usdToEgpController = TextEditingController(text: currency["usdToEgp"].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "تعديل ${currency["name"]}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 15),
              _buildTextField(rateController, "سعر التحويل", isDarkMode),
              const SizedBox(height: 10),
              _buildTextField(minTransferController, "أقل مبلغ للتحويل", isDarkMode),
              const SizedBox(height: 10),
              _buildTextField(usdToEgpController, "سعر الدولار بالجنيه", isDarkMode),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("إلغاء", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      double newRate = double.tryParse(rateController.text) ?? currency["rate"];
                      double newMinTransfer = double.tryParse(minTransferController.text) ?? currency["minTransfer"];
                      double newUsdToEgp = double.tryParse(usdToEgpController.text) ?? currency["usdToEgp"];

                      currenciesRef.doc(docId).update({
                        "rate": newRate,
                        "minTransfer": newMinTransfer,
                        "usdToEgp": newUsdToEgp,
                      });

                      Get.snackbar(
                        "تم التحديث",
                        "تم تعديل العملة بنجاح!",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("حفظ", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[200];
    final appBarColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "إدارة العملات",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: appBarColor,
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: currenciesRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد بيانات",
                  style: TextStyle(color: textColor),
                ),
              );
            }

            var currencies = snapshot.data!.docs;

            return ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                var doc = currencies[index];
                var currency = doc.data() as Map<String, dynamic>;

                return Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    title: Text(
                      currency["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      "💰 سعر التحويل: ${currency["rate"]}  |  🔻 أقل مبلغ: ${currency["minTransfer"]}  |  💵 سعر الدولار: ${currency["usdToEgp"]}",
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editCurrency(context, doc.id, currency),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// **تصميم حقل إدخال البيانات**
  Widget _buildTextField(TextEditingController controller, String label, bool isDarkMode) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDarkMode ? Colors.white54 : Colors.black54),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      keyboardType: TextInputType.number,
    );
  }
}