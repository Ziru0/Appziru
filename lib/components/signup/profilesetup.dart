import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../dbHelper/mongodb.dart';
import '../wrapper.dart';  // Import your Wrapper page here
import 'package:http/http.dart' as http;


class Profilesetup extends StatefulWidget {
  const Profilesetup({super.key});

  @override
  State<Profilesetup> createState() => _ProfilesetupState();
}

class _ProfilesetupState extends State<Profilesetup> {
  var fnameController = TextEditingController();
  var numberController = TextEditingController();
  var addressController = TextEditingController();
  var carInfoController = TextEditingController(); // Added controller for car info
  String? selectedRole; // Variable to store the selected role
  final List<String> roles = ['Driver', 'Passenger']; // Available roles
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await uploadImageToCloudinary(imageFile); // Upload to Cloudinary
      if (imageUrl != null) {
        setState(() {
          _profileImage = imageFile; // Update UI
        });
        print("Image Uploaded: $imageUrl");
      } else {
        print("Upload failed");
      }
    }
  }


  Future<String?> uploadImageToCloudinary(File imageFile) async {
    String cloudName = "dpiqvnwpk";  // Replace with your Cloudinary Cloud Name
    String uploadPreset = "fgf2cwjh";  // Replace with your Cloudinary Upload Preset

    var url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonData['secure_url']; // Return the Cloudinary-hosted image URL
    } else {
      print("Cloudinary Upload Error: ${jsonData['error']['message']}");
      return null;
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

      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      String firebaseId = user.uid;
      String? carInfo; // Variable to store car info

      // Upload image before inserting data
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await uploadImageToCloudinary(_profileImage!);
      }

      if (selectedRole == 'Driver') {
        carInfo = carInfoController.text;
        if (carInfo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Car information is required for drivers.")),
          );
          return;
        }
      }


      await _insertData(
        firebaseId,
        fnameController.text,
        numberController.text,
        addressController.text,
        selectedRole!,
        imageUrl, // Pass uploaded image URL
        carInfo, // Pass car info, can be null if not driver
      );

      if (mounted) {
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
      String firebaseId, String fName, String number, String address, String role, String? imageUrl, String? carInfo) async {

    var userData = await MongoDatabase.getOne(firebaseId);

    if (userData == null) {
      // If the user doesn't exist, insert a new one
      var newUser = {
        "firebaseId": firebaseId,
        "fullname": fName,
        "number": number,
        "address": address,
        "role": role,
        "profileImage": imageUrl,
        "driverId": null,
        "passengerId": null,
      };

      await MongoDatabase.insertUser(newUser);  // Call insert function
      userData = await MongoDatabase.getOne(firebaseId); // Fetch user again
    }

    if (userData == null || !userData.containsKey('_id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not found in database after insert.")),
      );
      return;
    }

    mongo.ObjectId objectId = userData['_id']; // Extract the MongoDB ObjectId

    Map<String, dynamic> updatedData = {
      "role": role,
      "profileImage": imageUrl,
      "driverId": null,
      "passengerId": null,
    };

    if (role == "Driver") {
      updatedData["driverId"] = objectId;
      // Insert car info into a new collection
      var driverInfo = {
        "firebaseId": firebaseId,
        "carInfo": carInfo,
        "userId": objectId, // Link to the user document
      };
      await MongoDatabase.insertDriver(driverInfo); // Assume this function exists in MongoDatabase
    } else if (role == "Passenger") {
      updatedData["passengerId"] = objectId;
    }

    await MongoDatabase.updateOne(firebaseId, fName, address, number, updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile updated successfully")),
    );

    _clearAll();
  }




  // Clear all form fields
  void _clearAll() {
    fnameController.text = "";
    numberController.text = "";
    addressController.text = "";
    selectedRole = null;
    carInfoController.text = ""; // Clear car info controller
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
              // Car Information Field - Conditionally Rendered
              if (selectedRole == 'Driver')
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: TextField(
                    controller: carInfoController,
                    decoration: const InputDecoration(
                      labelText: "Car Information",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
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