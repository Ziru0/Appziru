import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../../dbHelper/monggodb.dart';
import '../utils/app_colors.dart';
import '../views/invites.dart';
import '../views/payment.dart';
import '../views/promo_codes.dart';
import '../views/ride_history.dart';
import '../views/settings.dart';
import '../views/support.dart';


class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});


  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {

  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

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
      print('Error fetching profile data: $e');
    }
  }

  final user=FirebaseAuth.instance.currentUser;

  final TextEditingController destinationController = TextEditingController();
  final TextEditingController sourceController = TextEditingController();
  List<dynamic> suggestions = [];

  List<LatLng> routePoints = [];
  final LatLng startPoint = LatLng(8.56469, 123.3336);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(userName: "Harold Andrei Ruiz", userImage: null), // Assign
      appBar: AppBar(

        title: Text(
          "Home",
          style: GoogleFonts.poppins(),

        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Opens the drawer
            },
          ),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(8.56469, 123.3336),
          initialZoom: 14,
        ),
        children: [
          Stack(
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // These widgets should be on top of the map, hence in a stack
              buildProfileTile(
                name: profileData?['fullname'] ?? 'N/A', // Use the dynamic full name
                imageUrl: profileData?['profilePicture'], // Use the dynamic profile picture URL
              ),
              buildTextField(),
              buildBottomSheet(),
              buildTextFieldForSource(),
            ],
          ),
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
        decoration: const BoxDecoration(color: Colors.white70),
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
      top: 170,
      left: 20,
      right: 20,
      child: Container(
        width: Get.width,
        height: 50,
        padding: const EdgeInsets.only(left: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 4,
              blurRadius: 10,
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: destinationController,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Search for a destination',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon:
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                if (destinationController.text.isNotEmpty) {
                  await fetchAndSetRoute(destinationController.text);
                }
              },
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Future<void> searchAndShowRoute(String destination) async {
    try {
      // Geocode the destination to get latitude and longitude
      List<Location> locations = await locationFromAddress(destination);

      if (locations.isNotEmpty) {
        double destinationLat = locations.first.latitude;
        double destinationLng = locations.first.longitude;

        // Call your route fetching method here (e.g., using a routing API)
        List<LatLng> route = await fetchRouteToDestination(destinationLat, destinationLng);

        // Update the map with the new polyline
        setState(() {
          routePoints = route;
        });
      } else {
        print('No location found for $destination');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Future<List<LatLng>> fetchRouteToDestination(double destinationLat, double destinationLng) async {
    // Implement your routing logic here to fetch the route.
    // For example, you can call an API like OpenRouteService or Google Directions API.

    // Dummy route for now:
    return [
      LatLng(8.5896, 123.3336),  // Start point (your current location)
      LatLng(destinationLat, destinationLng), // Destination
    ];
  }

  Widget buildTextFieldForSource() {
    return Positioned(
      top: 230,
      left: 20,
      right: 20,
      child: Container(
        width: Get.width,
        height: 50,
        padding: EdgeInsets.only(left: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: TextFormField(
          controller: sourceController,
          readOnly: true,
          onTap: () async {
            buildSourceSheet(sourceController: sourceController);
          },

          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'From:',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                Icons.search,
              ),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget buildBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: Get.width * 0.8,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 4,
              blurRadius: 10,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            topLeft: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Container(
            width: Get.width * 0.6,
            height: 4,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }

  buildDrawer({String? userName, String? userImage}) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children:
        [
          // Drawer Header
          UserAccountsDrawerHeader(
            currentAccountPicture: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: profileData?['profilePicture'] == null // Check if profile picture is null
                    ? const DecorationImage(
                  image: AssetImage('assets/person.png'), // Default image
                  fit: BoxFit.fill,
                )
                    : DecorationImage(
                  image: NetworkImage(profileData!['profilePicture']), // Dynamic profile picture
                  fit: BoxFit.fill,
                ),
              ),
            ),
            accountName: Text(
              profileData?['fullname'] ?? "N/A", // Dynamic user full name or fallback
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              profileData?['email'] ?? "N/A", // Dynamic user email or fallback
              style: GoogleFonts.poppins(),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF181C14), // Drawer header background color
            ),
          ),


          // Drawer Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Menu", // Title text
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,

              ),
            ),
          ),

          // Drawer Items
          ListTile(
            title: const Text('Payment History'),
            onTap: () => Get.to(() => const PaymentScreen()),
          ),
          ListTile(
            title: const Text('Ride History'),
            onTap: ()  => Get.to(() => const RideHistoryScreen()),
          ),
          ListTile(
            title: const Text('Invite Friends'),
            onTap: ()  => Get.to(() => const InviteFriendsScreen()),
          ),
          ListTile(
            title: const Text('Promo Codes'),
            onTap: ()  => Get.to(() => const PromoCodePage()),
          ),
          ListTile(
            title: const Text('Settings'),
            onTap: ()  => Get.to(() => const SettingsPage()),
          ),
          ListTile(
            title: const Text('Support'),
            onTap: ()  => Get.to(() => const SupportPage()),
          ),
          ListTile(
            title: const Text('Log Out'),
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }


  void buildSourceSheet({
    required TextEditingController sourceController,
  }) {

    Get.bottomSheet(
        Container(
          width: Get.width,
          height: Get.height * 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Select Your Location",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Home Address",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Get.back(); // Close the bottom sheet
                  sourceController.text = "Home Address"; // Set the selected value
                },
                child: _buildAddressContainer("Home Address"),
              ),
              const SizedBox(height: 20),
              const Text(
                "Current Address",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  Get.back();
                  sourceController.text = "Current Address";
                },
                child: _buildAddressContainer("Business Address"),
              ),
              const SizedBox(height: 20),
              const Text(
                "Search for Address",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {

                        // Define the action to perform when the button is clicked
                        print("Search button pressed");
                      },
                      child: const Text(
                        "Search for Address",
                        style: TextStyle(

                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index]['properties']['label'];
                    final coordinates = suggestions[index]['geometry']['coordinates'];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        sourceController.text = suggestion;
                        Get.back(); // Close the bottom sheet
                        // Use coordinates as needed, for example:
                        fetchAndSetRoute(LatLng(coordinates[1], coordinates[0]) as String);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Future<void> fetchPlaceSuggestions(String query) async {
    const String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38'; // Replace with your API key
    final url =
        'https://api.openrouteservice.org/geocode/autocomplete?api_key=$apiKey&text=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          suggestions = data['features']; // Extract suggestions
        });
      } else {
        print("Failed to fetch suggestions: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }


  Widget _buildAddressContainer(String label) {
    return Container(
      width: Get.width,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 4,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }


  Future<void> fetchAndSetRoute(String destination) async {
    try {
      // Geocode destination to get its coordinates
      final destinationCoords = await geocodeDestination(destination);
      if (destinationCoords == null) {
        throw Exception("Unable to find destination coordinates.");
      }

      // Fetch the route between the start point and destination
      final routeDetails = await fetchRoute(startPoint, destinationCoords);

      setState(() {
        routePoints = routeDetails['routePoints'];
        final distance = routeDetails['distance'];
        final duration = routeDetails['duration'];
        final cost = routeDetails['cost'];

        // Show distance, duration, and cost to the user
        showRouteDetails(distance, duration, cost);
      });
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  void showRouteDetails(double distance, double duration, double cost) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Route Details",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text("Distance: ${distance.toStringAsFixed(2)} km"),
            Text("Duration: ${duration.toStringAsFixed(2)} minutes"),
            Text("Cost: ₱${cost.toStringAsFixed(2)}"),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showTaxis, // Function to show taxis
              icon: const Icon(Icons.local_taxi, color: Colors.white),
              label: const Text("Find Cabs"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Example function to show taxis
  void _showTaxis() {
    // Mock implementation to simulate taxi display
    print("Taxis are being shown on the map!");

    // Implement your logic to fetch and display taxis here.
    // Example: Add taxi markers to a map or update the UI.
  }



  /// Geocode destination address using OpenRouteService
  Future<LatLng?> geocodeDestination(String address) async {
    const String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38'; // Replace with your API key
    final url =
        'https://api.openrouteservice.org/geocode/search?api_key=$apiKey&text=$address';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        return LatLng(coords[1], coords[0]);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchRoute(LatLng start, LatLng end) async {
    const String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38'; // Replace with your API key
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Extract route details
      final coordinates = data['features'][0]['geometry']['coordinates'];
      final distance = data['features'][0]['properties']['segments'][0]['distance'] / 1000; // Convert meters to kilometers
      final duration = data['features'][0]['properties']['segments'][0]['duration'] / 60; // Convert seconds to minutes

      // Calculate cost (e.g., $1 per km)
      const double costPerKm = 15.0;
      final double cost = distance * costPerKm;

      // Convert coordinates to LatLng
      final routePoints = coordinates
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();

      return {
        'routePoints': routePoints,
        'distance': distance,
        'duration': duration,
        'cost': cost,
      };
    } else {
      throw Exception("Failed to fetch route.");
    }
  }


}
