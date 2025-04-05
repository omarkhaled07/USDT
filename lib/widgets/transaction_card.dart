import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../screens/transaction_details_screen_three.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionCard({super.key, required this.transaction});

  Color getStatusColor() {
    switch (transaction.status) {
      case "مؤكدة":
        return Colors.green;
      case "مرفوضة":
        return Colors.red;
      case "ملغية":
        return Colors.red;
      case "معلقة":
        return Colors.orange;
      case "جارى التنفيذ":
        return Colors.yellowAccent;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (transaction.status) {
      case "مؤكدة":
        return Icons.check_circle;
      case "مرفوضة":
        return Icons.cancel;
      case "ملغية":
        return Icons.cancel;
      case "معلقة":
        return Icons.hourglass_empty;
      case "جارى التنفيذ":
        return Icons.hourglass_bottom_outlined;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreenThree(transaction: transaction),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey.shade200,
            child: Icon(Icons.swap_horiz, color: isDarkMode ? Colors.white : Colors.black),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transaction.sendType,
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: isDarkMode ? Colors.blue[300] : Colors.blue),
              Expanded(
                child: Text(
                  transaction.receiveType,
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                  textAlign: TextAlign.end,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "المبلغ: ${transaction.sendAmount} ➝ ${transaction.receiveAmount}",
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
              Text(
                "رقم العملية: ${transaction.transactionNumber}",
                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: getStatusColor(),
              shape: BoxShape.circle,
            ),
            child: Icon(getStatusIcon(), color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}