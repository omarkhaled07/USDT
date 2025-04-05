import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late String userEmail;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> walletList = [];
  String? documentId;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ المستخدم غير مسجل الدخول.");
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          documentId = userDoc.id;
          userData = userDoc.data() as Map<String, dynamic>? ?? {};
          walletList = List<Map<String, dynamic>>.from(userData?['wallets'] ?? []);
        });
      } else {
        debugPrint("❌ لا توجد بيانات للمستخدم.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ لا توجد بيانات للمستخدم."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ خطأ في تحميل البيانات: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ حدث خطأ أثناء تحميل البيانات: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addWallet() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    String selectedWalletType = 'Vodafone Cash L.E';
    TextEditingController walletController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  "إضافة محفظة جديدة",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedWalletType,
                    decoration: InputDecoration(
                      labelText: "نوع المحفظة",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    items: ["Vodafone Cash L.E", "InstaPay L.E", "Papier USD", "Advcash USD", "Bitnance Pay USD", "Tron(TRC20) USD", "BNB Smart Chain (BEP20) USD", "Insta Pay USD", "RedotoPay USD"].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: TextStyle(fontSize: 18, color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedWalletType = value!;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: walletController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "رقم المحفظة",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (walletController.text.isNotEmpty && documentId != null) {
                          Map<String, dynamic> newWallet = {
                            'walletType': selectedWalletType,
                            'walletNumber': walletController.text,
                          };

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(documentId)
                                .update({
                              'wallets': FieldValue.arrayUnion([newWallet]),
                            });

                            setState(() {
                              walletList.add(newWallet);
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ تمت إضافة المحفظة بنجاح."),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            debugPrint("❌ خطأ أثناء حفظ البيانات: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ حدث خطأ أثناء حفظ البيانات: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ يرجى إدخال رقم المحفظة."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                      ),
                      child: const Text("حفظ", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("إلغاء", style: TextStyle(fontSize: 16, color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editWallet(int index) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    String selectedWalletType = walletList[index]['walletType']!;
    TextEditingController walletController = TextEditingController(text: walletList[index]['walletNumber']);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  "تعديل المحفظة",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedWalletType,
                    decoration: InputDecoration(
                      labelText: "نوع المحفظة",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    items: ["Vodafone Cash", "InstaPay"].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: TextStyle(fontSize: 18, color: textColor)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedWalletType = value!;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: walletController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "رقم المحفظة",
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    ),
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (walletController.text.isNotEmpty && documentId != null) {
                          Map<String, dynamic> updatedWallet = {
                            'walletType': selectedWalletType,
                            'walletNumber': walletController.text,
                          };

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(documentId)
                                .update({
                              'wallets': FieldValue.arrayRemove([walletList[index]]),
                            });
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(documentId)
                                .update({
                              'wallets': FieldValue.arrayUnion([updatedWallet]),
                            });

                            setState(() {
                              walletList[index] = updatedWallet;
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ تم تعديل المحفظة بنجاح."),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            debugPrint("❌ خطأ أثناء تعديل البيانات: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("❌ حدث خطأ أثناء تعديل البيانات: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ يرجى إدخال رقم المحفظة."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                      ),
                      child: const Text("حفظ التعديل", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("إلغاء", style: TextStyle(fontSize: 16, color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteWallet(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: const Text("هل أنت متأكد أنك تريد حذف هذه المحفظة؟"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(documentId)
                      .update({
                    'wallets': FieldValue.arrayRemove([walletList[index]]),
                  });

                  setState(() {
                    walletList.removeAt(index);
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ تم حذف المحفظة بنجاح."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  debugPrint("❌ خطأ أثناء حذف المحفظة: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ حدث خطأ أثناء حذف المحفظة: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=8b76fe22c80007a299747564ceed8f8a");

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    var responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      var data = json.decode(responseData.body);
      return data['data']['url'];
    } else {
      debugPrint("❌ فشل تحميل الصورة: ${responseData.body}");
      return null;
    }
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await uploadImage(imageFile);

      if (imageUrl != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(documentId).update({
            'profileImageUrl': imageUrl,
          });

          setState(() {
            userData?['profileImageUrl'] = imageUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ تم تحميل الصورة بنجاح."),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          debugPrint("❌ خطأ أثناء تحديث الصورة في Firestore: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ حدث خطأ أثناء تحديث الصورة: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ فشل تحميل الصورة."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text("الصفحة الشخصية", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        centerTitle: true,
        elevation: 5,
      ),
      body: userData == null
          ? Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.white,
        child: Center(
          child: Text("جارٍ تحميل المعلومات...", style: TextStyle(fontSize: 20, color: textColor)),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => pickAndUploadImage(),
              child: Hero(
                tag: 'profile-image',
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  backgroundImage: userData?['profileImageUrl'] != null
                      ? NetworkImage(userData!['profileImageUrl'])
                      : null,
                  child: userData?['profileImageUrl'] == null
                      ? Icon(Icons.account_circle, size: 110, color: Colors.teal)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userData?['name'] ?? 'اسم غير متوفر',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 5),
            Text(userData?['email'] ?? 'بريد إلكتروني غير متوفر', style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7))),
            Text(userData?['phone'] ?? 'رقم هاتف غير متوفر', style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7))),
            const SizedBox(height: 30),
            Text(
              "محافظك",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            if (walletList.isEmpty)
              Text(
                "لا توجد محافظ حالياً.",
                style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: walletList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: ListTile(
                    title: Text(walletList[index]['walletType'] ?? 'نوع المحفظة غير متوفر', style: TextStyle(color: textColor)),
                    subtitle: Text(walletList[index]['walletNumber'] ?? 'رقم المحفظة غير متوفر', style: TextStyle(color: textColor.withOpacity(0.7))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editWallet(index),
                          icon: Icon(Icons.edit, color: Colors.teal),
                        ),
                        IconButton(
                          onPressed: () => _deleteWallet(index),
                          icon: Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWallet,
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}