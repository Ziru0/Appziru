import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lage/components/tabpages/home_tab.dart';
import '../homepage.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white, // Back button color
          onPressed: () => Get.to(() => HomeTabPage()),
        ),
        title: Text(
          "Ride History",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF171717), // Dark theme background color
      ),
      body: Column(
        children: [
          // Ride History Content
          _buildRideHistoryList(),
        ],
      ),
      backgroundColor: const Color(0xFFF1F1F1), // Dark theme background color
    );
  }

  // Widget for Ride History List
  Widget _buildRideHistoryList() {
    final rides = [
      {"date": "Dec 1, 2024", "destination": "Central Park", "status": "Completed", "amount": "\$20"},
      {"date": "Nov 30, 2024", "destination": "Times Square", "status": "Completed", "amount": "\$15"},
      {"date": "Nov 28, 2024", "destination": "Brooklyn Bridge", "status": "Cancelled", "amount": "\$0"},
    ];

    return Expanded(
      child: ListView.builder(
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF282C21), // Dark card background color
            child: ListTile(
              leading: Icon(
                ride['status'] == "Completed"
                    ? Icons.check_circle
                    : ride['status'] == "Cancelled"
                    ? Icons.cancel
                    : Icons.access_time,
                color: ride['status'] == "Completed"
                    ? Colors.green
                    : ride['status'] == "Cancelled"
                    ? Colors.red
                    : Colors.orange,
              ),
              title: Text(
                ride['destination']!,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
              subtitle: Text(
                "Date: ${ride['date']} | Amount: ${ride['amount']}",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              trailing: Text(
                ride['status']!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: ride['status'] == "Completed"
                      ? Colors.green
                      : ride['status'] == "Cancelled"
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
