import 'package:expanse_mate/pages/add_transaction.dart';
import 'package:expanse_mate/pages/transaction_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Expenses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Loading indicator
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Display a welcome message with a button to add an expense
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Expanse Mate!',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No expenses found!',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final double amount = transaction['amount'];
              final String category = transaction['category'];
              final String notes = transaction['notes'];
              final DateTime date = (transaction['date'] as Timestamp).toDate();
              final String formattedDate = DateFormat.yMMMd().format(date);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.attach_money),
                  ),
                  title: Text(
                    '$category - \$${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: $formattedDate'),
                      if (notes.isNotEmpty) Text('Notes: $notes'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionDetailPage(transactionId: transaction.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      // Add Floating Action Button for adding more expenses
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Expense',
      ),
    );
  }
}
