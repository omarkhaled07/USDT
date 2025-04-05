import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // استيراد مكتبة Clipboard
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/transaction_model.dart';
import '../../services/transactions_service.dart';
import '../../widgets/transaction_card_admin.dart';

class AdminOrdersScreen extends StatelessWidget {
  final TransactionsService transactionsService = TransactionsService();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();

  AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey.shade100;
    final appBarColor = isDarkMode ? Colors.grey[800] : Colors.blue;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => isSearching.value
            ? TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "ابحث برقم المعاملة...",
            hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
            border: InputBorder.none,
          ),
          style: TextStyle(color: textColor),
          onChanged: (value) {
            searchQuery.value = value;
          },
        )
            : Text(
          "كل المعاملات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Obx(() => isSearching.value
              ? IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () {
              searchQuery.value = '';
              searchController.clear();
              isSearching.value = false;
            },
          )
              : IconButton(
            icon: Icon(Icons.search, color: textColor),
            onPressed: () {
              isSearching.value = true;
            },
          )),
        ],
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsService.getAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          final allTransactions = snapshot.data!.docs.map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              debugPrint("❌ خطأ في تحويل البيانات: $e");
              return null;
            }
          }).whereType<TransactionModel>().toList();

          return Obx(() {
            final filteredTransactions = allTransactions
                .where((transaction) =>
                transaction.transactionId.contains(searchQuery.value))
                .toList();

            if (filteredTransactions.isEmpty) {
              return _buildEmptyState(isDarkMode);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return GestureDetector(
                  onTap: () async {
                    // نسخ رقم المعاملة باستخدام Clipboard.setData
                    await Clipboard.setData(ClipboardData(text: transaction.transactionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("تم نسخ رقم المعاملة: ${transaction.transactionId}"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: TransactionCardAdmin(transaction: transaction),
                );
              },
            );
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.grey;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/empty.png", height: 150),
          const SizedBox(height: 20),
          Text(
            "لا توجد معاملات بعد!",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 10),
          Text(
            "لا يوجد أي معاملات حالياً.",
            style: TextStyle(fontSize: 14, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}