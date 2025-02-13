import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart' as mongo;  // Alias mongo_dart import.
import '../../dbHelper/MongoDBModeluser.dart';
import '../../dbHelper/monggodb.dart';

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

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _fetchProfileData();
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

  List<MongoDbModelUser> users = [];

  String getCurrentFirebaseUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  Future<void> fetchRoute() async {
    if (startCoordinates == null || endCoordinates == null) {
      print('🚨 Start or end coordinates are null!');
      return;
    }

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

        // 🔹 Extract polyline data first
        final geometry = data['routes'][0]['geometry'];
        final decodedPolyline = decodePolyline(geometry);

        // 🔹 Update UI to show the polyline immediately
        setState(() {
          polylinePoints = decodedPolyline;
        });

        // 🔹 Move the map to fit the polyline
        moveMapToPolyline();

        // 🔹 Extract route details
        final double distance = data['routes'][0]['summary']['distance'] / 1000; // in km
        final double duration = data['routes'][0]['summary']['duration'] / 60;   // in minutes
        final double cost = distance * 10;

        // 🔹 Show confirmation inside `setState()` after a delay
        Future.delayed(Duration(seconds: 5), () {
          print("🚀 Showing Ride Confirmation Sheet...");
          if (mounted) {
            Get.bottomSheet(
                buildRideConfirmationSheet(distance, duration, cost)
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

  Future<void> saveRideRequest(
      MongoDbModelUser selectedDriver, double distance, double duration, double cost) async {

    String firebaseUserId = getCurrentFirebaseUserId();
    MongoDbModelUser? loggedInUser = await MongoDatabase.getUser(firebaseUserId);

    if (loggedInUser != null) {
      // Create ride request with selected driver
      Map<String, dynamic> requestData = {
        "_id": mongo.ObjectId(), // ✅ Generate a new ObjectId
        "passengerId": loggedInUser.id.oid,
        "driverId": selectedDriver.id.oid,  // Assign selected driver
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
        "distance": distance,  // ✅ Fix: Use calculated distance
        "duration": duration,  // ✅ Fix: Use calculated duration
        "cost": cost,          // ✅ Fix: Use calculated cost
        "status": "pending",   // Initial status
      };

      await MongoDatabase.saveRequest(requestData);
      print("✅ Ride request saved with driver: ${selectedDriver.fullname}");
    } else {
      print("🚨 Failed to fetch user details!");
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

  MongoDbModelUser? selectedDriver; // ✅ Declare globally to persist selection


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(8.5872, 123.3403), // Coordinates for Dipolog City, PH
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints, // Use the polyline points here
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: markers.toList(),
              ),
            ],
          ),
          buildProfileTile(
            name: profileData?['fullname'] ?? 'N/A', // Use the dynamic full name
            imageUrl: profileData?['profilePicture'], // Use the dynamic profile picture URL
          ),
          buildTextField(),
          buildTextFieldForSource(), // Ensure this is displayed correctly
          buildCurrentLocationIcon(),
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
                          startCoordinates =
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
                          endCoordinates =
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


  bool isAgreed = false; // Add state variable

  Widget buildRideConfirmationSheet(double distance, double duration, double cost) {
    return StatefulBuilder(
      builder: (context, setState) => Container(
        width: Get.width,
        height: Get.height * 0.35, // Increased height for the agreement
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
            textWidget(text: 'Select a Driver:', fontSize: 18, fontWeight: FontWeight.bold),
            SizedBox(height: 10),
            buildDriversList(distance, duration, cost), // ✅ Pass the values
            SizedBox(height: 10),
            Divider(),
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
                  child: textWidget(
                    text: 'I agree to the terms and conditions.',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
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
                    print("✅ Selected Driver: ${selectedDriver!.fullname} - ${selectedDriver!.id.oid}");
                    saveRideRequest(selectedDriver!, distance, duration, cost);
                    Get.back();

                    // 🔹 Show Snackbar to notify passenger
                    Get.snackbar(
                      "Ride Request Sent",
                      "Waiting for the driver's approval...",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.blue,
                      colorText: Colors.white,
                      duration: Duration(seconds: 4),
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
                shape: StadiumBorder(),
                child: textWidget(text: 'Confirm', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  int selectedRide = 0;

  Widget buildDriversList(double distance, double duration, double cost) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: MongoDatabase.getData(),  // Fetch raw data from MongoDB
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: textWidget(text: "No drivers available", fontSize: 16));
        }

        // Convert the raw data (List<Map<String, dynamic>>) to List<MongoDbModelUser>
        List<MongoDbModelUser> users = snapshot.data!
            .map((data) => MongoDbModelUser.fromJson(data))
            .toList();

        // Filter the users where the role is 'Driver'
        List<MongoDbModelUser> filteredUsers = users
            .where((user) => user.role == 'Driver')
            .toList();

        // Debugging: Print the fetched users list
        print("Fetched users: ${filteredUsers.length}");

        return SizedBox(
          height: 100,
          child: StatefulBuilder(
            builder: (context, setState) {
              return ListView.builder(
                itemCount: filteredUsers.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, i) {
                  var driver = filteredUsers[i];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedRide = i;
                        selectedDriver = filteredUsers[i]; // ✅ Ensure assignment
                        print("🚀 Selected Driver Updated: ${selectedDriver!.fullname} - ${selectedDriver!.id.oid}");
                      });
                    },

                      child: buildDriverCard(driver, selectedRide == i, distance, duration, cost),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  buildDriverCard(MongoDbModelUser user, bool selected, double distance, double duration, double cost) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 90,
      width: 170,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: selected ? Color(0xff2DBB54).withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
              text: '${user.fullname ?? "No Name"}',  // Display the driver's name directly
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textWidget(
              text: 'Est. Fare: ₱${cost.toStringAsFixed(2)}',  // Estimated fare
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textWidget(
              text: 'ETA: ${duration.toStringAsFixed(2)} MIN',  // Estimated time of arrival
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textWidget(
              text: 'Distance: ${distance.toStringAsFixed(2)} km',  // Distance
              color: Colors.white.withOpacity(0.8),
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
