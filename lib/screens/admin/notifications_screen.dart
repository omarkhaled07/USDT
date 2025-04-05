import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _newNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _updateLastVisitTime();
    _loadNewNotificationsCount();
  }

  void _requestNotificationPermission() async {
    await OneSignal.Notifications.requestPermission(true);
  }

  Future<void> _updateLastVisitTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastVisitTime', DateTime.now().toIso8601String());
    setState(() {
      _newNotificationsCount = 0;
    });
  }

  Future<void> _loadNewNotificationsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitTime = prefs.getString('lastVisitTime');
    if (lastVisitTime != null) {
      final lastVisit = DateTime.parse(lastVisitTime);
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('timestamp', isGreaterThan: lastVisit)
          .get();
      setState(() {
        _newNotificationsCount = notifications.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final appBarColor = isDarkMode ? Colors.grey[800] : Colors.blueAccent;
    final iconColor = isDarkMode ? Colors.white : Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "الإشعارات",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarColor,
        elevation: 5,
        iconTheme: IconThemeData(color: textColor),
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: iconColor,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد إشعارات جديدة",
                style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return FutureBuilder<DateTime?>(
            future: _getLastVisitTime(),
            builder: (context, lastVisitSnapshot) {
              if (lastVisitSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: iconColor,
                  ),
                );
              }

              final lastVisitTime = lastVisitSnapshot.data;

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index].data() as Map<String, dynamic>;
                  final timestamp = notification['timestamp']?.toDate();
                  final formattedDate = timestamp != null
                      ? DateFormat('yyyy-MM-dd – hh:mm a').format(timestamp)
                      : 'بدون تاريخ';

                  final isNew = lastVisitTime == null || timestamp!.isAfter(lastVisitTime);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: isNew ? Colors.red : iconColor,
                      ),
                      title: Text(
                        notification['transactionId'] ?? 'بدون عنوان',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification['body'] ?? 'بدون محتوى',
                            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        final transactionId = notification['transactionId'] ?? 'غير متوفر';
                        FlutterClipboard.copy(transactionId).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("تم نسخ رقم العملية: $transactionId"),
                              backgroundColor: appBarColor,
                            ),
                          );
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  Future<DateTime?> _getLastVisitTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitTime = prefs.getString('lastVisitTime');
    return lastVisitTime != null ? DateTime.parse(lastVisitTime) : null;
  }
}