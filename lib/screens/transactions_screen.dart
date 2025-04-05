import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usdt_express/screens/user_profile_screen.dart';
import '../models/transaction_model.dart';
import '../services/transactions_service.dart';
import '../theme/theme_notifier.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import '../screens/login_screen.dart';

class TransactionsScreen extends StatelessWidget {
  final TransactionsService transactionsService = TransactionsService();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();

  TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => isSearching.value
            ? TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "ابحث برقم المعاملة",
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          onChanged: (value) {
            searchQuery.value = value;
          },
        )
            : const Text(
          "المعاملات",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Obx(() => isSearching.value
              ? IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              searchQuery.value = '';
              searchController.clear();
              isSearching.value = false;
            },
          )
              : IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              isSearching.value = true;
            },
          )),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey.shade100,
      drawer: _buildDrawer(context, themeNotifier),
      body: StreamBuilder<QuerySnapshot>(
        stream: transactionsService.getUserTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint("⚠️ لا توجد معاملات!");
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
                .where((transaction) => transaction.transactionId.contains(searchQuery.value))
                .toList();

            if (filteredTransactions.isEmpty) {
              return _buildEmptyState(isDarkMode);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                return TransactionCard(transaction: filteredTransactions[index]);
              },
            );
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeNotifier themeNotifier) {
    final isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 60),
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage("assets/logo.png"),
          ),
          const SizedBox(height: 15),
          Divider(thickness: 1, indent: 20, endIndent: 20, color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          ListTile(
            leading: Icon(Icons.person, color: isDarkMode ? Colors.blue[300] : Colors.blue),
            title: Text("الصفحة الشخصية", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.support_agent, color: isDarkMode ? Colors.green[300] : Colors.green),
            title: Text("التواصل مع الدعم", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () => _launchTelegram(context),
          ),
          const Divider(),
          SwitchListTile(
            title: Text("الوضع الداكن", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            value: isDarkMode,
            onChanged: (value) {
              themeNotifier.toggleTheme();
            },
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode ? Colors.amber : Colors.black,
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("تسجيل الخروج", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => LoginScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/empty.png", height: 150),
          const SizedBox(height: 20),
          Text(
            "لا توجد معاملات بعد!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "اضغط على الزر في الأسفل لإضافة معاملة جديدة.",
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _launchTelegram(BuildContext context) async {
    final Uri webUri = Uri.parse("https://t.me/officalUSDTexpress");
    try {
      if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        throw Exception("❌ لا يمكن فتح المتصفح!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ حدث خطأ أثناء فتح الرابط: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}