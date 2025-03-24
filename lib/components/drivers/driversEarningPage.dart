import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../dbHelper/mongodb.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({Key? key}) : super(key: key);

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  List<Map<String, dynamic>> rideRequests = [];
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String firebaseId = user.uid;

        // Fetch driver profile using Firebase UID
        var userCollection = MongoDatabase.db.collection("ziru");
        var driverData = await userCollection.findOne(mongo.where.eq("firebaseId", firebaseId));

        if (driverData == null || !driverData.containsKey("_id") || driverData["_id"] == null) {
          return;
        }

        // Extract and convert _id to ObjectId
        mongo.ObjectId driverObjectId = driverData["_id"] as mongo.ObjectId;

        // Fetch only completed ride requests
        List<Map<String, dynamic>> requests = await MongoDatabase.getCompletedRequests(driverObjectId);

        double earnings = requests.fold(0.0, (sum, ride) {
          double cost = (ride['cost'] is double) ? ride['cost'] : double.tryParse(ride['cost'].toString()) ?? 0.0;
          return sum + cost;
        });

        setState(() {
          rideRequests = requests;
          totalEarnings = earnings;
        });
      }
    } catch (e) {
      // Handle errors silently
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Earnings Display
            Card(
              elevation: 5,
              color: Colors.green[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Total Earnings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Php ${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ride Requests List
            Expanded(
              child: rideRequests.isEmpty
                  ? const Center(child: Text("No completed rides yet."))
                  : ListView.builder(
                itemCount: rideRequests.length,
                itemBuilder: (context, index) {
                  var ride = rideRequests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.directions_car, color: Colors.blue),
                      title: Text(ride['fullname'] ?? 'Unknown Passenger'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pickup: ${ride['coordinates']['start']['latitude']}, ${ride['coordinates']['start']['longitude']}"),
                          Text("Dropoff: ${ride['coordinates']['end']['latitude']}, ${ride['coordinates']['end']['longitude']}"),
                          Text("Fare: ₱${ride['cost'] != null ? ((ride['cost'] is double) ? ride['cost'] : double.tryParse(ride['cost'].toString()) ?? 0.0).toStringAsFixed(2) : '0.00'}"),
                          Text(
                            "Date: ${ride['timestamp'] != null ? DateTime.parse(ride['timestamp']).toLocal() : 'Unknown'}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
