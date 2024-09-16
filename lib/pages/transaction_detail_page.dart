import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;  // Pass the transaction ID to perform operations

  TransactionDetailPage({required this.transactionId});

  @override
  _TransactionDetailPageState createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactionDetails();  // Fetch the details of the selected transaction
  }

  // Fetch the transaction details from Firestore
  Future<void> _fetchTransactionDetails() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .doc(widget.transactionId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      _amountController.text = data['amount'].toString();
      _selectedCategory = data['category'];
      _notesController.text = data['notes'];
      _selectedDate = (data['date'] as Timestamp).toDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Transaction Details Tab
          _buildDetailsTab(),
          // Edit Transaction Tab
          _buildEditTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _deleteTransaction,
        child: Icon(Icons.delete),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Transaction Details View
  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount: \$${_amountController.text}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Category: $_selectedCategory',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          Text(
            'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          if (_notesController.text.isNotEmpty)
            Text(
              'Notes: ${_notesController.text}',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }

  // Edit Transaction Form
  Widget _buildEditTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Amount Input
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                return null;
              },
            ),
            SizedBox(height: 16.0),
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Food', 'Transport', 'Shopping', 'Salary'].map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            // Date Picker
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: _pickDate,
              ),
            ),
            SizedBox(height: 16.0),
            // Notes Input
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 32.0),
            // Save Button
            ElevatedButton(
              onPressed: _updateTransaction,
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick a date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to update the transaction
  Future<void> _updateTransaction() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .update({
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'notes': _notesController.text,
        'date': _selectedDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction updated successfully!')),
      );
    }
  }

  // Function to delete the transaction
  Future<void> _deleteTransaction() async {
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(widget.transactionId)
        .delete();

    Navigator.pop(context);  // Return to the home page
  }
}
