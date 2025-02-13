import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../dbHelper/monggodb.dart';
import '../../dbHelper/monggodb.dart';
import 'package:http/http.dart' as http;

import '../../wrapper.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  var fnameController = TextEditingController();
  var numberController = TextEditingController();
  var addressController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userData = await MongoDatabase.getUser(user.uid);
      if (userData != null) {
        setState(() {
          fnameController.text = userData.fullname ?? "";
          numberController.text = userData.number ?? "";
          addressController.text = userData.address ?? "";
          if (userData.profileImage != null) {
            _profileImage = File(userData.profileImage!);
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await uploadImageToCloudinary(imageFile);
      if (imageUrl != null) {
        setState(() {
          _profileImage = imageFile;
        });
        print("Image Uploaded: $imageUrl");
      } else {
        print("Upload failed");
      }
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    String cloudName = "dpiqvnwpk";
    String uploadPreset = "fgf2cwjh";

    var url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    var request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonData['secure_url'];
    } else {
      print("Cloudinary Upload Error: ${jsonData['error']['message']}");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return;
      }

      String firebaseId = user.uid;
      String? imageUrl;

      // Define updatedData first
      Map<String, dynamic> updatedData = {
        "fullname": fnameController.text,
        "number": numberController.text,
        "address": addressController.text,
      };

      if (_profileImage != null) {
        imageUrl = await uploadImageToCloudinary(_profileImage!);
        if (imageUrl != null) {
          updatedData["profileImage"] = imageUrl;
        }
      }

      await MongoDatabase.updateProfile(firebaseId, updatedData);
      await _loadUserData(); // Reload user data after update

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Center(
                child: ElevatedButton.icon(
                  onPressed: _updateProfile,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
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
