import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lage/components/views/homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dbHelper/monggodb.dart';
import '../wrapper.dart';  // Import your Wrapper page here

class Profilesetup extends StatefulWidget {
  const Profilesetup({super.key});

  @override
  State<Profilesetup> createState() => _ProfilesetupState();
}

class _ProfilesetupState extends State<Profilesetup> {
  var fnameController = TextEditingController();
  var numberController = TextEditingController();
  var addressController = TextEditingController();
  String? selectedRole; // Variable to store the selected role
  final List<String> roles = ['Driver', 'Passenger']; // Available roles
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

  // Save profile setup and navigate to the "Wrapper" page
  Future<void> _completeProfileSetup() async {
    try {
      if (selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a role.")),
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isProfileSetUp', true);

      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      String firebaseId = user.uid;

      // Insert data into MongoDB
      await _insertData(
        firebaseId,
        fnameController.text,
        numberController.text,
        addressController.text,
        selectedRole!,
      );

      // Ensure navigation is executed
      if (mounted) {
        // Delay navigation to give time for profile setup to complete
        await Future.delayed(const Duration(seconds: 2)); // Adjust time as needed

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Wrapper()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _insertData(
      String firebaseId, String fName, String number, String address, String role) async {
    Map<String, dynamic> updatedData = {
      "role": role, // Include the role in the data
    };

    var result = await MongoDatabase.updateOne(
        firebaseId, fName, address, number, updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Updated profile for: $firebaseId")));
    _clearAll();
  }

  // Clear all form fields
  void _clearAll() {
    fnameController.text = "";
    numberController.text = "";
    addressController.text = "";
    selectedRole = null;
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
              // Form Fields for Full Name, Phone Number, and Address
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
              const SizedBox(height: 20),
              // Role Selection Dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 30),
              // Button to complete profile setup
              Center(
                child: ElevatedButton.icon(
                  onPressed: _completeProfileSetup,
                  icon: const Icon(Icons.done),
                  label: const Text("Done"),  // Button text changed to "Done"
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
