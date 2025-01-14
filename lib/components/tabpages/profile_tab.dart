import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lage/components/tabpages/profilepages/Policy.dart';
import 'package:lage/components/tabpages/profilepages/my_profile.dart';
import 'package:lage/components/tabpages/profilepages/notifications.dart';


class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

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
        backgroundColor: Color(0xFF181C14),

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
                  CircleAvatar(
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
                              builder: (context) => ProfilePage(), // Replace with your target page
                            ),
                          );
                        },
                        child: Text(
                          "Harold Andrei Ruiz", // Replace with actual user name
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        "qwe123@example.com", // Replace with actual email
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF3C3D37)
                          ,
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
                onTap: () {
                  // Navigate to Edit Profile Page
                },
              ),
              buildAccountOption(
                title: "Change Password",
                icon: Icons.lock,
                onTap: () {
                  // Navigate to Change Password Page
                },
              ),
              buildAccountOption(
                title: "Payment Methods",
                icon: Icons.payment,
                onTap: () {
                  // Navigate to Payment Methods Page
                },
              ),
              buildAccountOption(
                title: "Ride Preferences",
                icon: Icons.directions_car,
                onTap: () {
                  // Navigate to Ride Preferences Page
                },
              ),
              const Divider(),

              // App Preferences
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

              // Other Options
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
                onTap: () {
                  // Handle Log Out
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
      leading: Icon(icon, color: Color(0xFF3C3D37)
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
