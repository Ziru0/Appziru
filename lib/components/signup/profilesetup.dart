import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lage/components/views/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../../dbHelper/monggodb.dart';

class Profilesetup extends StatefulWidget {
  const Profilesetup({super.key});

  @override
  State<Profilesetup> createState() => _ProfilesetupState();
}

class _ProfilesetupState extends State<Profilesetup> {
  var firebaseIdController = new TextEditingController();
  var fnameController = new TextEditingController();
  var numberController = new TextEditingController();
  var addressController = new TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Save profile setup and navigate to home
  Future<void> _completeProfileSetup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isProfileSetUp', true); // Set the flag that profile is completed
    var user = FirebaseAuth.instance.currentUser;
    print('user: $user');
    String firebaseId = user!.uid;
    // Insert data into MongoDB
    await _insertData(
        firebaseId,
        fnameController.text,
        numberController.text,
        addressController.text
    );

    _insertData(

        firebaseIdController.text,
        fnameController.text,
        numberController.text,
        addressController.text
    );

    // Navigate to Home Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to HomePage after setup
    );
  }

  Future<void> _insertData(String firebaseId, String fName, String number0, String address) async {
    Map<String, dynamic> updatedData = {
      "someOtherField": "value", // Add any other fields to update if needed
    };

    var result = await MongoDatabase.updateOne(firebaseId, fName, address, number0, updatedData); // Insert data into MongoDB
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("updated profile from: $firebaseId")));
    _clearAll();
  }

  // Clear all form fields
  void _clearAll() {
    fnameController.text = "";
    numberController.text = "";
    addressController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Picture'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Form Fields for First Name, Phone Number, and Address
              TextField(
                controller: fnameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 30),
              // Button to complete profile setup
              Center(
                child: ElevatedButton.icon(
                  onPressed: _completeProfileSetup, // Call the function to complete setup
                  icon: const Icon(Icons.save),
                  label: const Text("Complete Setup"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
