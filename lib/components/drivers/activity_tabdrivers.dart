import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../dbHelper/mongodb.dart';

class DriverActivityPage extends StatefulWidget {
  const DriverActivityPage({super.key});

  @override
  State<DriverActivityPage> createState() => _DriverActivityPageState();
}

class _DriverActivityPageState extends State<DriverActivityPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> rideHistory = [];
  Map<String, dynamic>? profileData;


  @override
  void initState() {
    super.initState();
    fetchDriverHistory();
    _fetchProfileData();

  }



// In your DriverActivityPage:
  Future<void> fetchDriverHistory() async {
    try {
      String? driverId = FirebaseAuth.instance.currentUser?.uid; // Firebase UID
      if (driverId == null) {
        setState(() => _isLoading = false);
        return;
      }
  
      List<Map<String, dynamic>> rides = await MongoDatabase.getDriverRides(driverId);

      setState(() {
        rideHistory = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }



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
      // print('Error fetching profile data: $e');
    }
  }
  final user=FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ride Activity",
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

            // Ride History List
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
                    distance: ride['distance'].toString(),  // ✅ Directly use 'distance'
                    duration: ride['duration'].toString(),  // ✅ Directly use 'duration'
                    cost: (ride['cost'] != null)
                        ? double.parse(ride['cost'].toString()).toStringAsFixed(2)
                        : '0.00',
                    status: ride['status'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for displaying ride details
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
