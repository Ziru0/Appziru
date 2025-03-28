import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lage/components/tabpages/terms_condition.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' as mongo;  // Alias mongo_dart import.
import '../../dbHelper/MongoDBModeluser.dart';
import '../../dbHelper/mongodb.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  Map<String, dynamic>? profileData;
  final RxBool isLoading = true.obs;

  // Fetch profile data from MongoDB
  Future<void> _fetchProfileData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String firebaseId = user.uid;
        var data = await MongoDatabase.getOne(firebaseId); // Fetch data based on firebaseId
        setState(() {
          profileData = data;
        });
        _listenForRideAcceptance(); // Start listening for ride acceptance after profile is fetched
      }
    } catch (e) {
      // print('Error fetching profile data: $e');
    }
  }
  final user=FirebaseAuth.instance.currentUser;


  late MapController mapController;
  TextEditingController destinationController = TextEditingController();
  TextEditingController sourceController = TextEditingController();

  List<String> suggestionsList = [];
  List<String> suggestionsList1 = [];

  LatLng? startCoordinates;
  LatLng? endCoordinates;

  List<LatLng> polylinePoints = []; // List to store polyline points

  List<LatLng> polylineCoordinates = [];

  Stream<Map<String, dynamic>?> get rideUpdates => _rideStreamController.stream;

  MongoDbModelUser? selectedDriver; // ✅ Declare globally to persist selection

  Map<String, dynamic>? acceptedRequest;
  Map<String, dynamic>? rideAcceptedDetails; // Store accepted ride details

  final _rideStreamController = StreamController<Map<String, dynamic>?>.broadcast();

  String? passengerId;

  List<MongoDbModelUser> users = [];

  Timer? _rideAcceptanceTimer; // Timer for ride acceptance listener

  List<LatLng> _driverLocations = []; // ✅ Store all driver markers
  List<Map<String, dynamic>> _driverData = [];


  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _fetchProfileData();
    _fetchAllDriverPinnedLocations(); // ✅ Fetch all drivers' locations
  }

  Future<void> _fetchAllDriverPinnedLocations() async {
    try {
      print("🔍 Fetching all drivers' pinned locations...");

      // Ensure MongoDB is connected
      if (MongoDatabase.db == null || !MongoDatabase.db.isConnected) {
        print("🔄 Reconnecting to MongoDB...");
        await MongoDatabase.connect();
      }

      var collection = MongoDatabase.db.collection("pinned_locations");
      var results = await collection.find().toList();

      if (results.isNotEmpty) {
        print("✅ Found ${results.length} pinned locations");

        List<LatLng> locations = [];
        List<Map<String, dynamic>> driverData = []; // Store full data (including names)

        for (var result in results) {
          if (result.containsKey("latitude") && result.containsKey("longitude")) {
            double lat = (result["latitude"] as num).toDouble();
            double lng = (result["longitude"] as num).toDouble();
            locations.add(LatLng(lat, lng));

            driverData.add({
              "fullname": result["fullname"] ?? "Unknown",
              "latitude": lat,
              "longitude": lng,
            });
          }
        }

        setState(() {
          _driverLocations = locations;
          _driverData = driverData; // Save driver info for later use
        });

        print("📍 Updated map with ${_driverLocations.length} driver locations");
      } else {
        print("🚨 No pinned locations found.");
      }
    } catch (e) {
      print("❌ Error fetching drivers' locations: $e");
    }
  }

  void _listenForRideAcceptance() async {
    if (profileData == null) return;
    var collection = MongoDatabase.db.collection('requests');
    var passengerId = profileData?['_id'].toHexString();

    _rideAcceptanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var request = await collection.findOne({
        'passengerId': passengerId,
        'status': 'accepted'
      });

      if (request != null) {
        setState(() {
          rideAcceptedDetails = request; // Store accepted request details
        });
        _rideAcceptanceTimer?.cancel(); // Stop the timer once accepted
      }
    });
  }

  void _cancelRide() async {
    if (rideAcceptedDetails == null) return; // Use rideAcceptedDetails

    var collection = MongoDatabase.db.collection('requests');
    await collection.updateOne(
      mongo.where.eq('_id', rideAcceptedDetails!['_id'] as mongo.ObjectId), // Use rideAcceptedDetails
      mongo.modify.set('status', 'cancelled'),
    );

    setState(() {
      rideAcceptedDetails = null; // Reset rideAcceptedDetails
      passengerId = null;
      polylinePoints.clear();
      _rideAcceptanceTimer?.cancel(); // Cancel ride acceptance timer
      _rideAcceptanceTimer = null;
    });

    _rideStreamController.add(null);
    Get.snackbar( // Notify user with snackbar
      "Ride Canceled",
      "Your ride request has been canceled.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<List<String>> fetchPlaceSuggestions(String query) async {
    final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
    final url =
        'https://api.openrouteservice.org/geocode/search?text=$query&api_key=$apiKey&boundary.country=PH&boundary.rect.min_lon=123.2915&boundary.rect.min_lat=8.5254&boundary.rect.max_lon=123.3605&boundary.rect.max_lat=8.6311';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<String> suggestions = [];
      for (var feature in data['features']) {
        suggestions.add(feature['properties']['label']);
      }
      return suggestions;
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<LatLng?> fetchCoordinates(String query) async {
    final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
    final url =
        'https://api.openrouteservice.org/geocode/search?text=$query&api_key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coordinates = data['features'][0]['geometry']['coordinates'];
        return LatLng(coordinates[1], coordinates[0]);
      }
    }
    return null;
  }

  String getCurrentFirebaseUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  Future<void> fetchRoute() async {
    if (startCoordinates == null || endCoordinates == null) {
      return;
    }

    print("📍 Passenger Location: ${startCoordinates?.latitude}, ${startCoordinates?.longitude}");

    final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
      final url = 'https://api.openrouteservice.org/v2/directions/driving-car';

    final body = {
      "coordinates": [
        [startCoordinates!.longitude, startCoordinates!.latitude],
        [endCoordinates!.longitude, endCoordinates!.latitude]
      ]
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

        // 🔹 Update UI to show the polyline immediately
        setState(() {
          polylinePoints = decodedPolyline;
        });

        // 🔹 Move the map to fit the polyline
        moveMapToPolyline();

        // 🔹 Extract route details
        final double distanceDecimal = data['routes'][0]['summary']['distance'] / 1000; // in km
        final double durationDecimal = data['routes'][0]['summary']['duration'] / 60;   // in minutes

        // ✅ Cost Calculation
        double baseFare = 15.0;
        double extraFarePerKm = 20.0;
        double radiusLimit = 2.5; // Radius in km

        double costDecimal = (distanceDecimal <= radiusLimit)
            ? baseFare
            : baseFare + ((distanceDecimal - radiusLimit) * extraFarePerKm);

        // ✅ Format to two decimal places as strings
        String distance = distanceDecimal.toStringAsFixed(2);
        String duration = durationDecimal.toStringAsFixed(2);
        String cost = costDecimal.toStringAsFixed(2);

        // 🔹 Show confirmation inside setState() after a delay
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            Get.bottomSheet(
                buildRideConfirmationSheet(distance, duration, cost) // Pass formatted strings
            );
          }
        });

      } else {
        print("❌ Failed to fetch route: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching route: $e");
    }
  }


// Modify the saveRideRequest function to accept the notes
  Future<void> saveRideRequest(
      MongoDbModelUser selectedDriver,
      String distance,
      String duration,
      String cost, {
        String? passengerNotes, // Make passengerNotes an optional parameter
      }) async {
    try {
      String firebaseUserId = getCurrentFirebaseUserId();
      print("🔍 Firebase User ID: $firebaseUserId");

      MongoDbModelUser? loggedInUser = await MongoDatabase.getUser(firebaseUserId);

      if (loggedInUser != null) {
        print("👤 Logged In User: ${loggedInUser.fullname}");

        Map<String, dynamic> requestData = {
          "_id": mongo.ObjectId(),
          "passengerId": loggedInUser.id.oid,
          "driverId": selectedDriver.driverId,
          "fullname": loggedInUser.fullname,
          "number": loggedInUser.number,
          "coordinates": {
            "start": {
              "longitude": startCoordinates?.longitude,
              "latitude": startCoordinates?.latitude,
            },
            "end": {
              "longitude": endCoordinates?.longitude,
              "latitude": endCoordinates?.latitude,
            }
          },
          "distance": distance,
          "duration": duration,
          "cost": cost,
          "status": "pending",
          "passengerNotes": passengerNotes, // Include the passenger notes
        };

        await MongoDatabase.saveRequest(requestData);
        print("✅ Ride request saved with driver: ${selectedDriver.fullname}");
      } else {
        print("🚨 Failed to fetch user details!");
      }
    } catch (e, stacktrace) {
      print("❌ Error saving ride request: $e");
      print(stacktrace);
    }
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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth radius in km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = R * c; // Distance in km

    // ✅ Debugging: Print actual calculated distance
    print("📏 Calculated Distance: ${distance.toStringAsFixed(3)} km "
        "between ($lat1, $lon1) and ($lat2, $lon2)");

    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(8.5872, 123.3403), // Example: Dipolog City, PH
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _driverLocations.map((location) {
                  var driverInfo = _driverData.firstWhere(
                        (data) => data["latitude"] == location.latitude && data["longitude"] == location.longitude,
                    orElse: () => {},
                  );

                  return Marker(
                    point: location,
                    width: 100, // Increased width to accommodate text
                    height: 80,  // Increased height for better layout
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            driverInfo.isNotEmpty ? driverInfo["fullname"] ?? "Unknown Driver" : "Unknown Driver",
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(Icons.car_rental, color: Colors.green, size: 50),
                      ],
                    ),
                  );
                }).toList(),
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints, // Use your existing polyline data
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...markers, // Existing markers

                  if (startCoordinates != null)
                    Marker(
                      point: startCoordinates!,
                      width: 50,
                      height: 50,
                      child: Icon(Icons.location_on, color: Colors.blue, size: 30),
                    ),

                  if (endCoordinates != null)
                    Marker(
                      point: endCoordinates!,
                      width: 50,
                      height: 50,
                      child: Icon(Icons.flag, color: Colors.red, size: 30),
                    ),
                ],
              ),
            ],
          ),
          buildProfileTile(
            name: profileData?['fullname'] ?? 'N/A',
            imageUrl: profileData?['profilePicture'],
          ),
          buildTextFieldForSource(),
          buildTextField(),
          buildCurrentLocationIcon(),
          _buildRideAcceptedWidget(),
        ],
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
                  "Where are you going?",
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

  Widget buildTextField() {
    return Positioned(
      top: 200,
      left: 20,
      right: 20,
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: destinationController,
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    suggestionsList = await fetchPlaceSuggestions(value);
                    setState(() {});
                  } else {
                    setState(() {
                      suggestionsList = [];
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for a destination',
                  border: InputBorder.none,
                ),
              ),
              if (suggestionsList.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: suggestionsList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(suggestionsList[index]),
                        onTap: () async {
                          destinationController.text = suggestionsList[index];
                          endCoordinates =
                          await fetchCoordinates(suggestionsList[index]);
                          suggestionsList = [];
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> markers = {};

  Widget buildTextFieldForSource() {
    return Positioned(
      top: 260,
      left: 20,
      right: 20,
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                spreadRadius: 2,
                blurRadius: 8,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: sourceController,
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    suggestionsList1 = await fetchPlaceSuggestions(value);
                    setState(() {});
                  } else {
                    setState(() {
                      suggestionsList1 = [];
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'From',
                  border: InputBorder.none,
                ),
              ),
              if (suggestionsList1.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: suggestionsList1.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(suggestionsList1[index]),
                        onTap: () async {
                          sourceController.text = suggestionsList1[index];
                          startCoordinates =
                          await fetchCoordinates(suggestionsList1[index]);
                          suggestionsList1 = [];
                          setState(() {});
                          await fetchRoute();

                          // Debug log
                          // print("Showing Ride Confirmation Sheet");

                          // Ensure display
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCurrentLocationIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, right: 8),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.black,
          child: Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRideAcceptedWidget() {
    if (rideAcceptedDetails == null) return SizedBox();

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
              Text(
                'Ride Accepted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 8),
              // You can display more details here if needed, like driver name etc.
              Text('Your ride request has been accepted by a driver.'),
              ElevatedButton( // Add Cancel Ride Button
                onPressed: _cancelRide,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Cancel Ride"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isAgreed = false; // Add state variable



  Widget buildRideConfirmationSheet(String distance, String duration, String cost) {
    TextEditingController notesController = TextEditingController();
    return StatefulBuilder(
      builder: (context, setState) => Container(
        width: Get.width,
        height: Get.height * 0.45, // Increased height to accommodate the notes
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey,
                ),
              ),
            ),
            textWidget(
              text: 'Select a Driver:',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: buildDriversList(distance, duration, cost), // ✅ Pass the values
            ),
            const SizedBox(height: 10),
            textWidget(
              text: 'Add Notes (Optional):',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter any specific instructions or notes for the driver...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Row(
              children: [
                Checkbox(
                  value: isAgreed,
                  onChanged: (value) {
                    setState(() {
                      isAgreed = value!;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                      );
                    },
                    child: textWidget(
                      text: 'I agree to the terms and conditions.',
                      fontSize: 14,
                      color: Colors.blue, // Make it look like a hyperlink
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: MaterialButton(
                onPressed: () {
                  if (!isAgreed) {
                    Get.snackbar(
                      "Agreement Required",
                      "Please agree to the terms before confirming.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }
                  if (selectedDriver != null) {
                    final passengerNotes = notesController.text.trim();
                    saveRideRequest(selectedDriver!, distance, duration, cost, passengerNotes: passengerNotes);
                    Get.back();

                    // 🔹 Show Snackbar to notify passenger
                    Get.snackbar(
                      "Ride Request Sent",
                      "Waiting for the driver's approval...",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  } else {
                    Get.snackbar(
                      "No Driver Selected",
                      "Please select a driver before confirming.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                color: isAgreed ? Colors.blue : Colors.grey, // Disable button if not agreed
                shape: const StadiumBorder(),
                child: textWidget(text: 'Confirm', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int selectedRide = 1;

  Widget buildDriversList(String distance, String duration, String cost) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDatabase.getDriversWithLocation(),  // Fetch driver locations
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: textWidget(text: "No drivers available", fontSize: 16));
        }

        List<MongoDbModelUser> drivers = snapshot.data!
            .map((data) => MongoDbModelUser.fromJson(data))
            .toList();

        print("✅ Total Drivers Found: ${drivers.length}");
        print("📍 Passenger Location: ${startCoordinates?.latitude}, ${startCoordinates?.longitude}");


        if (startCoordinates == null) {
          return Center(child: textWidget(text: "Waiting for location...", fontSize: 16));
        }

        // 🔹 Filter drivers within 500 meters
        // 🔹 Filter drivers within 1km (1000 meters)
        const double maxDistanceMeters = 1000.0; // 1 km

        drivers = drivers.where((driver) {
          print("🛠️ Checking driver: ${driver.fullname}");
          print("📦 Full driver data: $driver");  // Print entire object

          if (driver.latitude == null || driver.longitude == null) {
            print("⚠️ Skipping driver ${driver.fullname} due to missing coordinates.");
            return false;
          }

          print("📍 Driver Coordinates: ${driver.latitude}, ${driver.longitude}");
          print("📍 Passenger Coordinates: ${startCoordinates!.latitude}, ${startCoordinates!.longitude}");

          double distanceToPassenger = calculateDistance(
            startCoordinates!.latitude,
            startCoordinates!.longitude,
            driver.latitude!,
            driver.longitude!,
          );

          print("🚗 ${driver.fullname} Distance: ${distanceToPassenger.toStringAsFixed(3)} km");

          return (distanceToPassenger * 1000) <= 1000.0;
        }).toList();


        print("✅ Nearby Drivers: ${drivers.length}");

        if (drivers.isEmpty) {
          return Center(child: textWidget(text: "No nearby drivers found", fontSize: 16));
        }

        // 🔹 Sort remaining drivers by proximity (ascending order)
        drivers.sort((a, b) {
          double distanceA = calculateDistance(
            startCoordinates!.latitude,
            startCoordinates!.longitude,
            a.latitude!,
            a.longitude!,
          );
          double distanceB = calculateDistance(
            startCoordinates!.latitude,
            startCoordinates!.longitude,
            b.latitude!,
            b.longitude!,
          );

          return distanceA.compareTo(distanceB);
        });


        return SizedBox(
          height: 100,
          child: ListView.builder(
            itemCount: drivers.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (ctx, i) {
              var driver = drivers[i];
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedRide = i;
                    selectedDriver = drivers[i]; // Assign nearest driver
                  });
                },
                child: buildDriverCard(driver, selectedRide == i, distance, duration, cost),
              );
            },
          ),
        );
      },
    );
  }

  buildDriverCard(MongoDbModelUser user, bool selected, String distance, String duration, String cost) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 90,
      width: 170,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: selected
                ? const Color(0xff2DBB54).withAlpha((0.2 * 255).toInt())
                : Colors.grey.withAlpha((0.2 * 255).toInt()),
            offset: Offset(0, 5),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
        color: selected ? Color(0xff2DBB54) : Colors.grey,
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            textWidget(
              text: user.fullname ?? "No Name",  // Display the driver's name directly
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textWidget(
              text: 'Est. Fare: Php $cost',  // ✅ Display formatted string directly - NO toStringAsFixed(2)
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textWidget(
              text: 'ETA: $duration MIN',  // ✅ Display formatted string directly - NO toStringAsFixed(2)
              color: Colors.white.withAlpha((0.8 * 255).toInt()),
              fontSize: 12,
            ),
            textWidget(
              text: 'Distance: $distance km',  // ✅ Display formatted string directly - NO toStringAsFixed(2)
              color: Colors.white.withAlpha((0.8 * 255).toInt()),
              fontSize: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget textWidget({required String text,double fontSize = 12, FontWeight fontWeight = FontWeight.normal,Color color = Colors.black}){
    return Text(text, style: GoogleFonts.poppins(fontSize: fontSize,fontWeight: fontWeight,color: color),);
  }
}
