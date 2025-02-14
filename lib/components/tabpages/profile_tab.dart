import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lage/components/tabpages/profilepages/Policy.dart';
import 'package:lage/components/tabpages/profilepages/edit_profile.dart';
import 'package:lage/components/tabpages/profilepages/my_profile.dart';
import 'package:lage/components/tabpages/profilepages/notifications.dart';

import '../../dbHelper/monggodb.dart';
import '../signup/login_page.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Account",
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF181C14),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/omoda1.png'),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                        child: Text(
                          profileData?['fullname'] ?? 'N/A', // Dynamic User Full Name
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileData?['email'] ?? 'N/A', // Dynamic User Email
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF3C3D37),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Account Options
              Text(
                "Account Settings",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildAccountOption(
                title: "Edit Profile",
                icon: Icons.edit,
                onTap: () => Get.to(() => const EditProfile()),
              ),
              buildAccountOption(
                title: "Change Password",
                icon: Icons.lock,
                onTap: () {
                  // Navigate to Change Password Page
                },
              ),
              const Divider(),
              Text(
                "App Preferences",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildAccountOption(
                title: "Language",
                icon: Icons.language,
                onTap: () {
                  // Navigate to Language Settings
                },
              ),
              buildAccountOption(
                title: "Earn as a Driver",
                icon: Icons.car_rental_outlined,
                onTap: () {
                  // Navigate to Language Settings
                },
              ),
              buildAccountOption(
                title: "Notifications",
                icon: Icons.notifications,
                onTap: () => Get.to(() => const NotificationPage()),
              ),
              const Divider(),
              Text(
                "Others",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              buildAccountOption(
                title: "Privacy Policy",
                icon: Icons.privacy_tip,
                onTap: () => Get.to(() =>  PrivacyPolicyPage()),
              ),
              buildAccountOption(
                title: "Terms of Service",
                icon: Icons.article,
                onTap: () {
                  // Navigate to Terms of Service Page
                },
              ),
              buildAccountOption(
                title: "Log Out",
                icon: Icons.logout,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()), // Replace with your login screen widget
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  // Helper Method for Account Options
  Widget buildAccountOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF3C3D37),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
