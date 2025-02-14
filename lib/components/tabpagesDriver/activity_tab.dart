import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../dbHelper/monggodb.dart';

class ActivityTabPage extends StatefulWidget {
  const ActivityTabPage({super.key});

  @override
  State<ActivityTabPage> createState() => _ActivityTabPageState();
}

class _ActivityTabPageState extends State<ActivityTabPage> {
  List<Map<String, dynamic>> rideHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRideHistory();
  }

  Future<void> _fetchRideHistory() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Fetch ride history from MongoDB
        var data = await MongoDatabase.getRideHistory(userId);

        setState(() {
          rideHistory = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
        backgroundColor: const Color(0xFF181C14),
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

            // Ride History List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rideHistory.isEmpty
                  ? Center(
                child: Text(
                  "No ride history available",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.separated(
                itemCount: rideHistory.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  var ride = rideHistory[index];
                  return buildActivityItem(
                    icon: Icons.directions_car,
                    title: "Ride to ${ride['destination'] ?? 'Unknown'}",
                    subtitle: "From: ${ride['pickup'] ?? 'Unknown'}",
                    date: ride['date'] ?? 'Unknown Date',
                  );
                },
              ),
            ),
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
        color: const Color(0xFF3C3D37),
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
