import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = true; // Theme switch
  bool _notificationsEnabled = true; // Notifications toggle

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181C14), // Dark theme background
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF181C14), // Dark theme background
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Account Section
            _buildAccountSection(),

            const SizedBox(height: 20),

            // Theme Section
            _buildThemeSection(),

            const SizedBox(height: 20),

            // Notifications Section
            _buildNotificationsSection(),

            const SizedBox(height: 20),

            // Help Section
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  // Widget for Account Section
  Widget _buildAccountSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.account_circle, color: Colors.white),
        title: Text(
          "Account Settings",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          // Navigate to Account Settings Page (implement as needed)
        },
      ),
    );
  }

  // Widget for Theme Section
  Widget _buildThemeSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.color_lens, color: Colors.white),
        title: Text(
          "Dark Mode",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: Switch(
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
          },
          activeColor: Colors.green,
        ),
      ),
    );
  }

  // Widget for Notifications Section
  Widget _buildNotificationsSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.white),
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: Switch(
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          activeColor: Colors.green,
        ),
      ),
    );
  }

  // Widget for Help Section
  Widget _buildHelpSection() {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.help_outline, color: Colors.white),
        title: Text(
          "Help & Support",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward, color: Colors.white),
        onTap: () {
          // Navigate to Help & Support Page (implement as needed)
        },
      ),
    );
  }
}
