import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../dbHelper/mongodb.dart';

class ActivityPage extends StatefulWidget {
  final bool isDriver; // Flag to determine if the user is a driver or passenger
  const ActivityPage({super.key, required this.isDriver});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> rideHistory = [];

  @override
  void initState() {
    super.initState();
    fetchRideHistory();
  }

  Future<void> fetchRideHistory() async {
    try {
      String? firebaseId = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch rides based on user type
      List<Map<String, dynamic>> rides = widget.isDriver
          ? await MongoDatabase.getDriverActivityRides(firebaseId)
          : await MongoDatabase.getPassengerRides(firebaseId);

      setState(() {
        rideHistory = rides;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching ride history: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDriver ? "Driver Activity" : "Passenger Activity",
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
            Text(
              "Recent Rides",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Completed and failed rides are displayed below.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rideHistory.isEmpty
                  ? Center(
                child: Text(
                  "No completed or failed rides available.",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.separated(
                itemCount: rideHistory.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  var ride = rideHistory[index];
                  return buildActivityItem(
                    icon: ride['status'] == 'completed'
                        ? Icons.check_circle
                        : Icons.cancel,
                    distance: ride['distance']?.toString() ?? '0.0',
                    duration: ride['duration']?.toString() ?? '0 min',
                    cost: ride['cost'] != null
                        ? double.parse(ride['cost'].toString()).toStringAsFixed(2)
                        : '0.00',
                    status: ride['status'] ?? 'unknown',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActivityItem({
    required IconData icon,
    required String distance,
    required String duration,
    required String cost,
    required String status,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 40,
        color: status == 'completed' ? Colors.green : Colors.red,
      ),
      title: Text(
        "Distance: $distance km",
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "Duration: $duration min\nFare: ₱$cost",
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      ),
      trailing: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: status == 'completed' ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
