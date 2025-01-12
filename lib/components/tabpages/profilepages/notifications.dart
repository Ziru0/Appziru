import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
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
            // Notification List
            _buildNotificationItem(
              title: "Payment Successful",
              subtitle: "Your payment of \$150 has been processed successfully.",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
            _buildNotificationItem(
              title: "New Ride Request",
              subtitle: "You have received a new ride request from a passenger.",
              icon: Icons.directions_car,
              iconColor: Colors.blue,
            ),
            _buildNotificationItem(
              title: "Promo Code Applied",
              subtitle: "You have successfully applied a promo code for your next ride.",
              icon: Icons.local_offer,
              iconColor: Colors.orange,
            ),
            _buildNotificationItem(
              title: "Ride Canceled",
              subtitle: "Your ride from Dec 10, 2024 has been canceled by the driver.",
              icon: Icons.cancel,
              iconColor: Colors.red,
            ),
            // More notifications can be added here
          ],
        ),
      ),
    );
  }

  // Widget for Individual Notification Item
  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      color: const Color(0xFF282C21), // Dark card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () {
          // Add functionality to handle notification tap
          // For example, navigate to the detailed notification page
        },
      ),
    );
  }
}
