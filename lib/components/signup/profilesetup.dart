import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lage/components/tabpages/home_tab.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../../dbHelper/MongoDbModel.dart';
import '../../dbHelper/monggodb.dart';

class Profilesetup extends StatefulWidget {
  const Profilesetup({super.key});

  @override
  State<Profilesetup> createState() => _ProfilesetupState();
}

class _ProfilesetupState extends State<Profilesetup> {
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

    // Insert data into MongoDB
    _insertData(
      fnameController.text,
      numberController.text,
      addressController.text,
    );

    // Navigate to Home Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeTabPage()), // Navigate to HomePage after setup
    );
  }

  Future<void> _insertData(String fName, String number0, String address) async {
    var _id = M.ObjectId();
    final data = MongoDbModel(
      id: _id,
      firstname: fName,
      number: number0,
      address: address,
    );

    var result = await MongoDatabase.insert(data); // Insert data into MongoDB
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inserted ID " + _id.$oid)));
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
                  labelText: "First Name",
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
