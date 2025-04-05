import 'package:flutter/material.dart';

import 'notifications_screen.dart';

class NotificationIcon extends StatefulWidget {
  @override
  _NotificationIconState createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  int _newNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNewNotificationsCount();
  }

  Future<void> _loadNewNotificationsCount() async {
    // ... (نفس الكود السابق)
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications, color: textColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );
          },
        ),
        if (_newNotificationsCount > 0)
          Positioned(
            right: 5,
            top: 5,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300), // مدة الرسوم المتحركة
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  '$_newNotificationsCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}