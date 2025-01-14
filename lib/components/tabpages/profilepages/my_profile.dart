import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../dbHelper/monggodb.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fetch profile data from MongoDB
  Future<void> _fetchProfileData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String firebaseId = user.uid;
        var data = await MongoDatabase.getOne(firebaseId); // Fetch data based on firebaseId
        setState(() {
          profileData = data;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: profileData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: profileData!['profileImage'] != null
                    ? NetworkImage(profileData!['profileImage'])
                    : null,
                child: profileData!['profileImage'] == null
                    ? const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // Display Name
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Full Name'),
              subtitle: Text(profileData!['fName'] ?? 'N/A'),
            ),
            const Divider(),
            // Display Phone Number
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone Number'),
              subtitle: Text(profileData!['number'] ?? 'N/A'),
            ),
            const Divider(),
            // Display Address
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Address'),
              subtitle: Text(profileData!['address'] ?? 'N/A'),
            ),
            const Divider(),
            // Edit Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()), // Navigate to setup page
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
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
    );
  }
}
