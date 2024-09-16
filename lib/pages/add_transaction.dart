import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionPage extends StatefulWidget {
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  // Static categories list
  final List<String> _staticCategories = ['Food', 'Transport', 'Shopping', 'Salary'];

  // All categories list
  List<String> _categories = [];

  // Date formatter
  String get _formattedDate => DateFormat.yMMMd().format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'),
        actions: [
          IconButton(
            icon: Icon(Icons.category),
            onPressed: () {
              Navigator.pushNamed(context, '/categories');
            },
          ),
        ],
      ),
      body: Padding(
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
                items: _categories.map((category) {
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
                title: Text('Date: $_formattedDate'),
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
              // Save/Cancel Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Save transaction to Firestore
                        _saveTransaction();
                      }
                    },
                    child: Text('Save'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
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

  // Function to save the transaction
  void _saveTransaction() async {
    final String amount = _amountController.text;
    final String category = _selectedCategory;
    final String notes = _notesController.text;

    try {
      // Add the transaction to Firestore
      await FirebaseFirestore.instance.collection('transactions').add({
        'amount': double.parse(amount),
        'category': category,
        'date': _selectedDate,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Function to show a success message in a dialog box
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Transaction saved successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Navigate back to home page
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to fetch dynamic categories from Firestore
  void _fetchCategories() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final List<String> userCategories = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      setState(() {
        _categories = [..._staticCategories, ...userCategories, 'Other'];
        _selectedCategory = _categories.isNotEmpty ? _categories.first : 'Food'; // Default category
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }
}