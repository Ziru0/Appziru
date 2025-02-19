// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:mongo_dart/mongo_dart.dart' as mongo;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import '../../dbHelper/mongodb.dart';
// import 'package:lage/components/views/invites.dart';
// import 'package:lage/components/views/payment.dart';
// import 'package:lage/components/views/promo_codes.dart';
// import 'package:lage/components/views/ride_history.dart';
// import 'package:lage/components/views/settings.dart';
// import 'package:lage/components/views/support.dart';
//
// class DriverHomePage extends StatefulWidget {
//   const DriverHomePage({super.key});
//
//   @override
//   _DriverHomePageState createState() => _DriverHomePageState();
// }
//
// class _DriverHomePageState extends State<DriverHomePage> {
//   Map<String, dynamic>? profileData;
//   late MapController mapController;
//   List<LatLng> polylinePoints = []; // List to store polyline points
//   List<Map<String, dynamic>> rideRequests = [];
//   Map<String, dynamic>? acceptedRequest;
//   bool isAvailable = true;
//
//   @override
//   void initState() {
//     super.initState();
//     mapController = MapController();
//     _fetchProfileData();
//   }
//
//   void _fetchProfileData() async {
//     try {
//       var user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         var data = await MongoDatabase.getOne(user.uid);
//         if (data != null) {
//           setState(() => profileData = data);
//           _listenForRideRequests();
//         }
//       }
//     } catch (e) {
//       print("Error fetching profile data: $e");
//     }
//   }
//
//   void _listenForRideRequests() async {
//     if (profileData == null) return;
//     var collection = MongoDatabase.db.collection('requests');
//     var driverId = profileData?['_id'].toHexString();
//     while (mounted) {
//       var requests = await collection.find({
//         'driverId': driverId,
//         'status': 'pending'
//       }).toList();
//       setState(() {
//         rideRequests = requests;
//       });
//       await Future.delayed(const Duration(seconds: 5));
//     }
//   }
//
//   Future<void> fetchRouteForDriver(Map<String, dynamic> request) async {
//     if (profileData == null) {
//       print('🚨 Driver profile data is NULL! Ensure it is loaded before calling this function.');
//       return;
//     }
//
//     print("🔍 Driver Profile Data: $profileData"); // Print profileData for debugging
//
//     if (profileData!['coordinates'] == null ||
//         profileData!['coordinates']['lat'] == null ||
//         profileData!['coordinates']['lng'] == null) {
//       print('🚨 Driver coordinates are missing or NULL!');
//       return;
//     }
//
//     var driverLocation = LatLng(
//       profileData!['coordinates']['lat'],
//       profileData!['coordinates']['lng'],
//     );
//
//     var start = LatLng(
//       request['coordinates']['start']['latitude'],
//       request['coordinates']['start']['longitude'],
//     );
//     var end = LatLng(
//       request['coordinates']['end']['latitude'],
//       request['coordinates']['end']['longitude'],
//     );
//
//     print("✅ Driver Location: $driverLocation"); // Print extracted coordinates
//
//     final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
//     final url = 'https://api.openrouteservice.org/v2/directions/driving-car';
//
//     final body = {
//       "coordinates": [
//         [driverLocation.longitude, driverLocation.latitude],
//         [start.longitude, start.latitude],
//         [end.longitude, end.latitude]
//       ]
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Authorization': apiKey,
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final geometry = data['routes'][0]['geometry'];
//         final decodedPolyline = decodePolyline(geometry);
//
//         setState(() {
//           polylinePoints = decodedPolyline;
//         });
//
//         moveMapToPolyline();
//       } else {
//         print("❌ Failed to fetch route: ${response.body}");
//       }
//     } catch (e) {
//       print("❌ Error fetching route: $e");
//     }
//   }
//
//
//   void _acceptRideRequest(Map<String, dynamic> request) async {
//     if (profileData == null) {
//       print("🚨 Driver profile is not loaded yet!");
//       return;
//     }
//
//     // Update status in MongoDB
//     await MongoDatabase.db.collection('requests').updateOne(
//       mongo.where.eq('_id', request['_id'] as mongo.ObjectId),
//       mongo.modify.set('status', 'accepted'),
//     );
//
//     setState(() {
//       rideRequests.remove(request);
//       acceptedRequest = request;
//     });
//
//     // ✅ Fetch and display route for driver
//     fetchRouteForDriver(request);
//   }
//
//
//   void moveMapToPolyline() {
//     if (polylinePoints.isEmpty) return;
//
//     double minLat = polylinePoints.first.latitude;
//     double maxLat = polylinePoints.first.latitude;
//     double minLng = polylinePoints.first.longitude;
//     double maxLng = polylinePoints.first.longitude;
//
//     for (LatLng point in polylinePoints) {
//       if (point.latitude < minLat) minLat = point.latitude;
//       if (point.latitude > maxLat) maxLat = point.latitude;
//       if (point.longitude < minLng) minLng = point.longitude;
//       if (point.longitude > maxLng) maxLng = point.longitude;
//     }
//
//     // Compute center of the polyline
//     double centerLat = (minLat + maxLat) / 2;
//     double centerLng = (minLng + maxLng) / 2;
//
//     // Estimate a good zoom level (tweak as needed)
//     double latDiff = maxLat - minLat;
//     double lngDiff = maxLng - minLng;
//     zoomLevel = (latDiff > lngDiff) ? 14.0 - (latDiff * 5) : 14.0 - (lngDiff * 5);
//     zoomLevel = zoomLevel.clamp(10.0, 18.0); // Keep zoom within a reasonable range
//
//     // Move the map
//     mapController.move(LatLng(centerLat, centerLng), zoomLevel);
//   }
//
//   double zoomLevel = 13.0; // Default zoom level
//
//   void _declineRideRequest(Map<String, dynamic> request) async {
//     var collection = MongoDatabase.db.collection('requests');
//     await collection.updateOne(
//         mongo.where.eq('_id', request['_id'] as mongo.ObjectId),
//         mongo.modify.set('status', 'declined'));
//     setState(() {
//       rideRequests.remove(request);
//     });
//   }
//
//
//   List<LatLng> decodePolyline(String encoded) {
//     List<LatLng> polyline = [];
//     int index = 0, len = encoded.length;
//     int lat = 0, lng = 0;
//
//     while (index < len) {
//       int shift = 0, result = 0;
//       int b;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lat += deltaLat;
//
//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1f) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
//       lng += deltaLng;
//
//       polyline.add(LatLng(lat / 1E5, lng / 1E5));
//     }
//
//     return polyline;
//   }
//
//   void _toggleAvailability() async {
//     setState(() {
//       isAvailable = !isAvailable;
//     });
//     var collection = MongoDatabase.db.collection('drivers');
//     await collection.updateOne(
//         mongo.where.eq('_id', profileData?['_id']),
//         mongo.modify.set('isAvailable', isAvailable));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: buildDrawer(),
//       appBar: AppBar(title: Text("Driver Dashboard", style: GoogleFonts.poppins())),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: mapController,
//             options: MapOptions(
//               initialCenter: LatLng(8.5872, 123.3403),
//               initialZoom: 15,
//             ),
//             children: [
//               TileLayer(
//                   urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
//                   subdomains: ['a', 'b', 'c']),
//               PolylineLayer(
//                 polylines: [
//                   Polyline(points: polylinePoints, strokeWidth: 4.0, color: Colors.blue),
//                 ],
//               ),
//             ],
//           ),
//           buildProfileTile(
//             name: profileData?['fullname'] ?? 'N/A',
//             imageUrl: profileData?['profilePicture'],
//           ),
//           _buildRideRequestWidget(),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _toggleAvailability,
//         backgroundColor: isAvailable ? Colors.green : Colors.red,
//         child: Icon(isAvailable ? Icons.check : Icons.close),
//       ),
//     );
//   }
//
//   Widget _buildRideRequestWidget() {
//     if (rideRequests.isEmpty) return SizedBox();
//     var request = rideRequests.first;
//     return Positioned(
//       bottom: 20,
//       left: 20,
//       right: 20,
//       child: Card(
//         elevation: 5,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Ride Request from ${request['fullname']}'),
//               Text('Distance: ${request['distance']} km'),
//               Text('Cost: PHP ${request['cost']}'),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () => _acceptRideRequest(request),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                     child: Text("Accept"),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => _declineRideRequest(request),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                     child: Text("Decline"),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   buildDrawer({String? userName, String? userImage}) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children:
//         [
//           // Drawer Header
//           UserAccountsDrawerHeader(
//             currentAccountPicture: Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 image: profileData?['profilePicture'] == null // Check if profile picture is null
//                     ? const DecorationImage(
//                   image: AssetImage('assets/person.png'), // Default image
//                   fit: BoxFit.fill,
//                 )
//                     : DecorationImage(
//                   image: NetworkImage(profileData?['profilePicture']), // Dynamic profile picture
//                   fit: BoxFit.fill,
//                 ),
//               ),
//             ),
//             accountName: Text(
//               profileData?['fullname'] ?? "N/A", // Dynamic user full name or fallback
//               style: GoogleFonts.poppins(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             accountEmail: Text(
//               profileData?['email'] ?? "N/A", // Dynamic user email or fallback
//               style: GoogleFonts.poppins(),
//             ),
//             decoration: const BoxDecoration(
//               color: Color(0xFF181C14), // Drawer header background color
//             ),
//           ),
//
//
//           // Drawer Title
//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               "Menu", // Title text
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//
//               ),
//             ),
//           ),
//
//           // Drawer Items
//           ListTile(
//             title: const Text('Payment History'),
//             onTap: () => Get.to(() => const PaymentScreen()),
//           ),
//           ListTile(
//             title: const Text('Ride History'),
//             onTap: ()  => Get.to(() => const RideHistoryScreen()),
//           ),
//           ListTile(
//             title: const Text('Invite Friends'),
//             onTap: ()  => Get.to(() => const InviteFriendsScreen()),
//           ),
//           ListTile(
//             title: const Text('Promo Codes'),
//             onTap: ()  => Get.to(() => const PromoCodePage()),
//           ),
//           ListTile(
//             title: const Text('Settings'),
//             onTap: ()  => Get.to(() => const SettingsPage()),
//           ),
//           ListTile(
//             title: const Text('Support'),
//             onTap: ()  => Get.to(() => const SupportPage()),
//           ),
//           ListTile(
//             title: const Text('Log Out'),
//             onTap: () {
//               FirebaseAuth.instance.signOut();
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget buildProfileTile({required String? name, required String? imageUrl}) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: name == null
//           ? const Center(
//         child: CircularProgressIndicator(),
//       )
//           : Container(
//         width: Get.width,
//         height: Get.width * 0.5,
//         padding:
//         const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 image: imageUrl == null
//                     ? const DecorationImage(
//                   image: AssetImage('assets/person.png'),
//                   fit: BoxFit.fill,
//                 )
//                     : DecorationImage(
//                   image: NetworkImage(imageUrl),
//                   fit: BoxFit.fill,
//                 ),
//               ),
//             ),
//             const SizedBox(
//               width: 15,
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 RichText(
//                   text: TextSpan(
//                     children: [
//                       const TextSpan(
//                         text: 'Good Morning, ',
//                         style:
//                         TextStyle(color: Colors.black, fontSize: 14),
//                       ),
//                       TextSpan(
//                         text: name,
//                         style: const TextStyle(
//                           color: Color(0xFF3C3D37),
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Text(
//                   "Waiting for Passenger?",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }