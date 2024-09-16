import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAddingCategory = false;
  String _spokenText = ""; // Store spoken text here

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Category Input with Submit Button
            _buildAddCategoryField(),
            SizedBox(height: 20.0),
            // Display Existing Categories
            _buildCategoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryField() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'New Category',
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            _isAddingCategory
                ? CircularProgressIndicator() // Show loader when adding a category
                : ElevatedButton(
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
              label: Text(_isListening ? 'Listening...' : 'Tap to Speak'),
              onPressed: _showSpeechDialog, // Show dialog for speech
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.redAccent : Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No categories available.'));
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final String name = category['name'];

              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeCategory(category.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Add category with Firestore
  void _addCategory() async {
    final newCategory = _categoryController.text.trim();
    if (newCategory.isNotEmpty) {
      setState(() {
        _isAddingCategory = true;
      });

      try {
        await FirebaseFirestore.instance.collection('categories').add({
          'name': newCategory,
          'userId': _auth.currentUser?.uid,
        });

        _categoryController.clear();
        Fluttertoast.showToast(msg: 'Category added successfully!');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error adding category: $e');
      }

      setState(() {
        _isAddingCategory = false;
      });
    } else {
      Fluttertoast.showToast(msg: 'Please enter a category name.');
    }
  }

  // Remove category from Firestore
  void _removeCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
      Fluttertoast.showToast(msg: 'Category removed successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error removing category: $e');
    }
  }

  // Show a dialog for speech recognition
  void _showSpeechDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hearing, size: 64, color: Colors.deepPurple),
              SizedBox(height: 10),
              Text(
                _spokenText.isEmpty ? 'Listening...' : _spokenText,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _categoryController.text = _spokenText; // Transfer spoken text to text field
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    _listen(); // Start listening when dialog opens
  }

  // Function to listen to speech and convert it into text
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() {
          if (val == 'done') {
            _isListening = false;
          }
        }),
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _spokenText = val.recognizedWords; // Update dynamically
            _categoryController.text = _spokenText; // Update dialog text field
          });
        });
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

}
