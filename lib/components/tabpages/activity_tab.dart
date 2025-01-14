import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityTabPage extends StatelessWidget {
  const ActivityTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity",
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF181C14),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              "Recent Activities",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Here's what you've been up to lately.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Activity List
          ],
        ),
      ),
    );
  }

  // Helper method for creating activity items
  Widget buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 40,
        color: Color(0xFF3C3D37),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      ),
      trailing: Text(
        date,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
}
