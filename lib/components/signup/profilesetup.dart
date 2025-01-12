import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as M;

import '../../dbHelper/MongoDbModel.dart';
import '../../dbHelper/monggodb.dart';

void main() {
  runApp(const ProfileSetupApp());
}

class ProfileSetupApp extends StatelessWidget {
  const ProfileSetupApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Setup',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProfileSetupPage(),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _insertData(String fName , String lName , String address) async {
    var _id = M.ObjectId();
    final data = MongoDbModel(id: _id, fullname: fName, number: lName, address: address);
    var result = await MongoDatabase.insert(data);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inserted ID " + _id.$oid)));
    _clearAll();
  }

  void _clearAll(){
    _fullNameController.text = "";
    _phoneNumberController.text = "";
    _addressController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Column(
                    children: [
                      if (_profileImage != null)
                        CircleAvatar(
                          backgroundImage: FileImage(_profileImage!),
                          radius: 60,
                        )
                      else
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 60,
                          child: Icon(Icons.person, size: 60),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Upload Picture'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 3,
                  validator: (value) =>
                  value!.isEmpty
                      ? 'Enter your address'
                      : null,
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(onPressed: () {
              _insertData(_fullNameController.text,_phoneNumberController.text,_addressController.text);
                }, child: Text("Insert Data"))
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
