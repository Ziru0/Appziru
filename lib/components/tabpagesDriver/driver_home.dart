import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../dbHelper/monggodb.dart';


class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  Map<String, dynamic>? profileData;
  late MapController mapController;
  List<LatLng> polylinePoints = [];
  List<Map<String, dynamic>> rideRequests = [];
  Map<String, dynamic>? acceptedRequest;
  bool isAvailable = true;
  LatLng? startCoordinates;
  LatLng? endCoordinates;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var data = await MongoDatabase.getOne(user.uid);
        if (data != null) {
          setState(() => profileData = data);
            _listenForRideRequests();
        }
      }
    } catch (e) {
    }
  }

  void _listenForRideRequests() async {
    if (profileData == null) return;
    var collection = MongoDatabase.db.collection('requests');
    var driverId = profileData?['_id'].toHexString();
    while (mounted) {
      var requests = await collection.find({
        'driverId': driverId,
        'status': 'pending'
      }).toList();
      setState(() {
        rideRequests = requests;
      });
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _acceptRideRequest(Map<String, dynamic> request) async {
    var collection = MongoDatabase.db.collection('requests');
    await collection.updateOne(
      mongo.where.eq('_id', request['_id'] as mongo.ObjectId),
      mongo.modify.set('status', 'accepted'),
    );

    setState(() {
      rideRequests.remove(request);
      acceptedRequest = request;
    });

    // ✅ Extract start & end coordinates
    LatLng? start = LatLng(
        request['coordinates']['start']['latitude'],
        request['coordinates']['start']['longitude']
    );
    LatLng? end = LatLng(
        request['coordinates']['end']['latitude'],
        request['coordinates']['end']['longitude']
    );

    // ✅ Assign coordinates for route fetching
    startCoordinates = start;
    endCoordinates = end;

    // ✅ Fetch and display the route
    await fetchRoute();
    }

  Future<void> fetchRoute() async {
    if (startCoordinates == null || endCoordinates == null) {
      return;
    }

    final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
    final url = 'https://api.openrouteservice.org/v2/directions/driving-car';

    final body = {
      "coordinates": [
        [startCoordinates!.longitude, startCoordinates!.latitude],
        [endCoordinates!.longitude, endCoordinates!.latitude]
      ],
      "instructions": false
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔹 Extract polyline data
        final geometry = data['routes'][0]['geometry'];
        final decodedPolyline = decodePolyline(geometry);

        setState(() {
          polylinePoints = decodedPolyline;  // ✅ Update polyline on the map
        });

        moveMapToPolyline(); // ✅ Move the map to fit the route
      } else {
      }
    } catch (e) {
    }
  }

  double zoomLevel = 13.0; // Default zoom level

  void moveMapToPolyline() {
    if (polylinePoints.isEmpty) return;

    double minLat = polylinePoints.first.latitude;
    double maxLat = polylinePoints.first.latitude;
    double minLng = polylinePoints.first.longitude;
    double maxLng = polylinePoints.first.longitude;

    for (LatLng point in polylinePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Compute center of the polyline
    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;

    // Estimate a good zoom level (tweak as needed)
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    zoomLevel = (latDiff > lngDiff) ? 14.0 - (latDiff * 5) : 14.0 - (lngDiff * 5);
    zoomLevel = zoomLevel.clamp(10.0, 18.0); // Keep zoom within a reasonable range

    // Move the map
    mapController.move(LatLng(centerLat, centerLng), zoomLevel);
  }

  List<LatLng> decodePolyline(String encoded)   {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  void _declineRideRequest(Map<String, dynamic> request) async {
    var collection = MongoDatabase.db.collection('requests');
    await collection.updateOne(
        mongo.where.eq('_id', request['_id'] as mongo.ObjectId),
        mongo.modify.set('status', 'declined'));
    setState(() {
      rideRequests.remove(request);
    });
  }

  void _toggleAvailability() async {
    setState(() {
      isAvailable = !isAvailable;
    });
    var collection = MongoDatabase.db.collection('drivers');
    await collection.updateOne(
        mongo.where.eq('_id', profileData?['_id']),
        mongo.modify.set('isAvailable', isAvailable));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Dashboard", style: GoogleFonts.poppins())),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(8.5872, 123.3403),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                  urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c']),
              PolylineLayer(
                polylines: [
                  Polyline(points: polylinePoints, strokeWidth: 4.0, color: Colors.blue),
                ],
              ),
            ],
          ),
          buildProfileTile(
            name: profileData?['fullname'] ?? 'N/A',
            imageUrl: profileData?['profilePicture'],
          ),
          _buildRideRequestWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAvailability,
        backgroundColor: isAvailable ? Colors.green : Colors.red,
        child: Icon(isAvailable ? Icons.check : Icons.close),
      ),
    );
  }

  Widget _buildRideRequestWidget() {
    if (rideRequests.isEmpty) return SizedBox();
    var request = rideRequests.first;
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ride Request from ${request['fullname']}'),
              Text('Distance: ${request['distance']} km'),
              Text('Cost: PHP ${request['cost']}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _acceptRideRequest(request),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Accept"),
                  ),
                  ElevatedButton(
                    onPressed: () => _declineRideRequest(request),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Decline"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProfileTile({required String? name, required String? imageUrl}) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: name == null
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        width: Get.width,
        height: Get.width * 0.5,
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: imageUrl == null
                    ? const DecorationImage(
                  image: AssetImage('assets/person.png'),
                  fit: BoxFit.fill,
                )
                    : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Good Morning, ',
                        style:
                        TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          color: Color(0xFF3C3D37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  "Waiting for Passenger?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}
