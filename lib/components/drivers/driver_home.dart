import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../dbHelper/mongodb.dart';


class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  DriverHomePageState createState() => DriverHomePageState();
}

class DriverHomePageState extends State<DriverHomePage> {
  Map<String, dynamic>? profileData;
  late MapController mapController;
  List<LatLng> polylinePoints = [];
  List<Map<String, dynamic>> rideRequests = [];
  Map<String, dynamic>? acceptedRequest;
  bool isAvailable = true;
  LatLng? startCoordinates;
  LatLng? endCoordinates;
  Timer? _rideRequestTimer; // Timer for ride request polling
  bool isPinLocationInputVisible = false; // State for pin location input visibility
  final TextEditingController _pinLocationController = TextEditingController(); // Controller for pin location input
  List<String> _suggestions = [];


  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _rideRequestTimer?.cancel(); // Cancel timer to prevent memory leaks
    _pinLocationController.dispose(); // Dispose the controller
    super.dispose();
  }
  Future<String?> getCurrentDriverId() async {
    if (profileData == null) {
      print("❌ profileData is null in getCurrentDriverId"); // Debugging print
      return null;
    }
    String? driverId = profileData?['_id'].toHexString();  // Ensure '_id' is correctly retrieved
    print("✅ Driver ID retrieved: $driverId"); // Debugging print
    return driverId;
  }


  void _fetchProfileData() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var data = await MongoDatabase.getOne(user.uid);
        if (data != null) {
          setState(() => profileData = data);
          _startListeningForRideRequests(); // Start listening after profile data is loaded
          print("✅ Profile data fetched successfully: $profileData"); // Debugging print
        } else {
          print("❌ No profile data found for user ${user.uid}"); // Debugging print
        }
      } else {
        print("❌ No user logged in"); // Debugging print
      }
    } catch (e) {
      print("❌ Error fetching profile data: $e"); // Debugging print
    }
  }

  void _listenForRideRequests() async {
    if (profileData == null) {
      print("❌ profileData is null in _listenForRideRequests, cannot fetch requests."); // Debugging print
      return;
    }
    var collection = MongoDatabase.db.collection('requests');
    var driverId = profileData?['_id'].toHexString();

    var requests = await collection.find({
      'driverId': driverId,
      'status': 'pending'
    }).toList();

    List<Map<String, dynamic>> newRequests = List<Map<String, dynamic>>.from(requests);

    // Check for cancellations in existing rideRequests
    for (var existingRequest in rideRequests) {
      bool stillPending = newRequests.any((req) => req['_id'].toHexString() == existingRequest['_id'].toHexString());
      if (!stillPending) {
        // Request is no longer in pending requests, check if it was cancelled
        var cancelledRequest = await collection.findOne(mongo.where.id(existingRequest['_id']));
        if (cancelledRequest != null && cancelledRequest['status'] == 'cancelled') {
          _showPassengerCancelledNotification(cancelledRequest);
        }
      }
    }

    setState(() {
      rideRequests = newRequests;
    });
  }

  void _startListeningForRideRequests() {
    if (_rideRequestTimer != null && _rideRequestTimer!.isActive) {
      print("Timer already active, not restarting."); // Debugging print
      return; // Timer already active
    }
    _rideRequestTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _listenForRideRequests();
      print("🔄 Polling for ride requests..."); // Debugging print
    });
    print("▶️ Ride request timer started."); // Debugging print
  }

  void _showPassengerCancelledNotification(Map<String, dynamic> request) {
    Get.snackbar(
      "Ride Request Cancelled",
      "The passenger ${request['fullname']} has cancelled the ride request.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5), // Adjust duration as needed
    );
    // Optionally remove it from local rideRequests list if you want to immediately remove from UI
    setState(() {
      rideRequests.removeWhere((req) => req['_id'] == request['_id']);
    });
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
      print("❌ startCoordinates or endCoordinates is null, cannot fetch route."); // Debugging print
      return;
    }

    final apiKey = 'YOUR_OPENROUTESERVICE_API_KEY'; // Replace with your actual API key
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
        print("✅ Route data fetched successfully: $data"); // Debugging print

        // 🔹 Extract polyline data
        final geometry = data['routes'][0]['geometry'];
        final decodedPolyline = decodePolyline(geometry);

        setState(() {
          polylinePoints = decodedPolyline;  // ✅ Update polyline on the map
        });

        moveMapToPolyline(); // ✅ Move the map to fit the route
      } else {
        print("❌ Failed to fetch route. Status code: ${response.statusCode}, Body: ${response.body}"); // Debugging print
      }
    } catch (e) {
      print("❌ Error fetching route: $e"); // Debugging print
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
    Get.snackbar( // Notify driver with snackbar
      "Ride Request Declined",
      "The ride request from ${request['fullname']} has been declined.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange, // Use orange to indicate declined/cancelled
      colorText: Colors.white,
    );
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

  void _completeRide(String status) async {
    if (acceptedRequest == null) return;

    var collection = MongoDatabase.db.collection('requests');
    await collection.updateOne(
      mongo.where.eq('_id', acceptedRequest!['_id'] as mongo.ObjectId),
      mongo.modify.set('status', status),
    );

    setState(() {
      acceptedRequest = null;
      polylinePoints.clear(); // Clear polyline after completion
    });
  }

  void _togglePinLocationInputVisibility() {
    setState(() {
      isPinLocationInputVisible = !isPinLocationInputVisible;
      if (!isPinLocationInputVisible) {
        _pinLocationController.clear(); // Clear text when hiding input
      }
    });
  }

  Widget _buildPinLocationFAB() {
    return Positioned(
      bottom: 20,
      right: 20, // Move to bottom right
      child: FloatingActionButton(
        heroTag: "pinLocationFab",
        onPressed: _togglePinLocationInputVisibility,
        backgroundColor: Colors.grey,
        child: Icon(Icons.location_pin),
      ),
    );
  }

  Widget _buildAvailabilityFAB() {
    return Positioned(
      bottom: 20,
      left: 20, // Move to bottom left
      child: FloatingActionButton(
        heroTag: "availabilityFab",
        onPressed: _toggleAvailability,
        backgroundColor: isAvailable ? Colors.green : Colors.red,
        child: Icon(isAvailable ? Icons.check : Icons.close),
      ),
    );
  }

// Pin Location Input (Bottom Right)
  LatLng? _searchedLocation; // Store searched location

  Future<void> _savePinnedLocationToDatabase(String driverId, String fullname, LatLng location) async {
    try {
      // 🔹 Ensure MongoDB is connected
      if (MongoDatabase.db == null || !MongoDatabase.db.isConnected) {
        await MongoDatabase.connect(); // Reconnect if needed
      }

      // 🔹 Reference the collection
      var collection = MongoDatabase.db.collection("pinned_locations");

      // 🔹 Insert pinned location data
      var result = await collection.insertOne({
        "driverId": driverId,
        "fullname": fullname,
        "locationName": _pinLocationController.text, // Save the location name for easier deletion
        "latitude": location.latitude,
        "longitude": location.longitude,
        "timestamp": DateTime.now().toIso8601String(),
      });

      if (result.isSuccess) {
        print("✅ Pinned location saved successfully!");
      } else {
        print("❌ Failed to save pinned location.");
      }
    } catch (e) {
      print("❌ Error saving pinned location: $e");
    }
  }


  Future<void> _searchLocation(String query) async {
    try {
      print("🔎 Searching location for query: $query");
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        setState(() {
          _searchedLocation = LatLng(location.latitude, location.longitude);
          _pinLocationController.text = query;
          mapController.move(_searchedLocation!, 15);
        });

        print("✅ Location found: ${location.latitude}, ${location.longitude}");

        // Fetch driver ID dynamically
        String? driverId = await getCurrentDriverId();
        String? driverFullname = profileData?['fullname']; // Get fullname from profileData

        if (driverId != null && driverFullname != null) {
          await _savePinnedLocationToDatabase(driverId, driverFullname, _searchedLocation!);
        } else {
          print("❌ Error: Driver ID or Fullname not found!");
        }
      } else {
        print("❌ No locations found for query: $query");
      }
    } catch (e) {
      print("❌ Error searching location: $e");
    }
  }

  Future<void> _removePinnedLocation(String locationName) async {
    if (locationName.isEmpty) return;

    try {
      print("🗑 Removing pinned location: $locationName");

      // 🔹 Fetch the driver ID
      String? driverId = await getCurrentDriverId();
      if (driverId == null) {
        print("❌ Error: Driver ID not found!");
        return;
      }

      // 🔹 Ensure MongoDB is connected
      if (MongoDatabase.db == null || !MongoDatabase.db.isConnected) {
        await MongoDatabase.connect(); // Reconnect if needed
      }

      // 🔹 Reference the collection
      var collection = MongoDatabase.db.collection("pinned_locations");

      // 🔹 Delete the document based on driverId and location name
      var result = await collection.deleteOne({
        "driverId": driverId,
        "fullname": profileData?['fullname'],
        "locationName": locationName
      });

      if (result.isSuccess) {
        setState(() {
          _pinLocationController.clear();
          _searchedLocation = null;
        });
        print("✅ Location removed successfully!");
      } else {
        print("❌ Failed to remove location.");
      }
    } catch (e) {
      print("❌ Error removing pinned location: $e");
    }
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

  void _onTextChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      List<String> suggestions = await fetchPlaceSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _pinLocationController.text = suggestion;
    _searchLocation(suggestion);
    setState(() {
      _suggestions = []; // Clear suggestions after selection
    });
  }

  Widget _buildPinLocationInput() {
    if (!isPinLocationInputVisible) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 80,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Card(
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: Get.width * 0.5,
                child: Column(
                  children: [
                    TextField(
                      controller: _pinLocationController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        border: InputBorder.none,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _searchLocation(_pinLocationController.text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removePinnedLocation(_pinLocationController.text),
                            ),
                          ],
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      onChanged: _onTextChanged, // Fetch suggestions as user types
                      onSubmitted: (query) => _searchLocation(query),
                    ),
                    if (_suggestions.isNotEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                        child: Column(
                          children: _suggestions
                              .map((suggestion) => ListTile(
                            title: Text(suggestion),
                            onTap: () => _onSuggestionSelected(suggestion),
                          ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                subdomains: ['a', 'b', 'c'],
              ),
              if (_searchedLocation != null) // Show marker if a location is searched
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _searchedLocation!,
                      width: 100,
                      height: 80,
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
                              profileData?['fullname'] ?? 'Driver',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.location_pin, color: Colors.red, size: 50),
                        ],
                      ),
                    ),
                  ],
                ),

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
          _buildAcceptedRideWidget(),
          _buildPinLocationInput(), // Now positioned at bottom right
          _buildPinLocationFAB(),  // FAB for pinning location (Bottom Right)
          _buildAvailabilityFAB(), // FAB for availability (Bottom Left)
        ],
      ),
    );
  }


  bool isTermsAccepted = false;

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
              Text(
                'Ride Request from ${request['fullname']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Distance: ${request['distance']} km'),
              Text('Cost: PHP ${request['cost']}'),
              SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: isTermsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        isTermsAccepted = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      "I agree to the Terms and Conditions",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: isTermsAccepted ? () => _acceptRideRequest(request) : null,
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

  Widget _buildAcceptedRideWidget() {
    if (acceptedRequest == null) return SizedBox();

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
                'Ride Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Passenger: ${acceptedRequest?['fullname'] ?? 'N/A'}'),
              Text('Distance: ${acceptedRequest?['distance']} km'),
              Text('Estimated Time: ${acceptedRequest?['estimatedTime']} mins'),
              Text('Cost: Php ${acceptedRequest?['cost']}'),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _completeRide('completed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Done"),
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