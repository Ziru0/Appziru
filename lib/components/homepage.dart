// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class Homepage extends StatefulWidget {
//   @override
//   _HomepageState createState() => _HomepageState();
// }
//
// class _HomepageState extends State<Homepage> {
//   List<LatLng> routePoints = [];
//   double distance = 0.0; // Distance in kilometers
//   double duration = 0.0; // Duration in minutes
//   double ratePerKm = 15.0; // Rate per kilometer in currency units
//   double totalCost = 0.0; // Total cost
//
//   TextEditingController destinationController = TextEditingController();
//   TextEditingController startPointController = TextEditingController(); // New controller
//
//   LatLng startPoint = LatLng(8.56469, 123.3336); // Default starting point
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Street Directions",
//           style: GoogleFonts.poppins(),
//         ),
//       ),
//       drawer: buildDrawer(userName: "Harold Andrei Ruiz", userImage: null),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: MapOptions(
//               initialCenter: startPoint,
//               initialZoom: 14,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 subdomains: ['a', 'b', 'c'],
//               ),
//               if (routePoints.isNotEmpty)
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: routePoints,
//                       color: Colors.blue,
//                       strokeWidth: 4.0,
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           buildSearchBar(),
//           buildStartPointSearchBar(), // New search bar for start point
//           if (distance > 0 && duration > 0)
//             Positioned(
//               bottom: 10,
//               left: 10,
//               right: 10,
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 6,
//                       spreadRadius: 4,
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   "Distance: ${distance.toStringAsFixed(2)} km, Duration: ${duration.toStringAsFixed(0)} minutes, Cost: ₱${totalCost.toStringAsFixed(15)}",
//                   style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//
//         ],
//       ),
//     );
//   }
//
//   Widget buildSearchBar() {
//     return Positioned(
//       top: 20,
//       left: 10,
//       right: 10,
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: destinationController,
//               decoration: InputDecoration(
//                 hintText: "Enter destination",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.search),
//             onPressed: () async {
//               if (destinationController.text.isNotEmpty) {
//                 await fetchAndSetRoute(startPoint, destinationController.text);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget buildStartPointSearchBar() {
//     return Positioned(
//       top: 70,
//       left: 10,
//       right: 10,
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: startPointController,
//               decoration: InputDecoration(
//                 hintText: "Enter starting point",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: Icon(Icons.search),
//             onPressed: () async {
//               if (startPointController.text.isNotEmpty) {
//                 await fetchAndSetStartPoint(startPointController.text);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> fetchAndSetRoute(LatLng start, String destination) async {
//     try {
//       final destinationCoords = await geocodeDestination(destination);
//       if (destinationCoords == null) {
//         throw Exception("Unable to find destination coordinates.");
//       }
//
//       final routeData = await fetchRoute(start, destinationCoords);
//       setState(() {
//         routePoints = routeData['route'];
//         distance = routeData['distance'] / 1000; // Convert meters to kilometers
//         duration = routeData['duration'] / 60; // Convert seconds to minutes
//         totalCost = distance * ratePerKm; // Calculate total cost
//       });
//     } catch (e) {
//       print("Error fetching route: $e");
//     }
//   }
//
//   Future<void> fetchAndSetStartPoint(String start) async {
//     try {
//       final startCoords = await geocodeDestination(start);
//       if (startCoords == null) {
//         throw Exception("Unable to find starting point coordinates.");
//       }
//
//       setState(() {
//         startPoint = startCoords;
//       });
//     } catch (e) {
//       print("Error fetching start point: $e");
//     }
//   }
//
//   Future<LatLng?> geocodeDestination(String address) async {
//     const String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38';
//     final url =
//         'https://api.openrouteservice.org/geocode/search?api_key=$apiKey&text=$address';
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['features'].isNotEmpty) {
//         final coords = data['features'][0]['geometry']['coordinates'];
//         return LatLng(coords[1], coords[0]);
//       }
//     }
//     return null;
//   }
//
//   Future<Map<String, dynamic>> fetchRoute(LatLng start, LatLng end) async {
//     const String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38';
//     final url =
//         'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}';
//
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final coordinates = data['features'][0]['geometry']['coordinates'];
//       final routePoints = coordinates
//           .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
//           .toList();
//
//       final distance = data['features'][0]['properties']['segments'][0]['distance'];
//       final duration = data['features'][0]['properties']['segments'][0]['duration'];
//
//       return {
//         'route': routePoints,
//         'distance': distance,
//         'duration': duration,
//       };
//     } else {
//       throw Exception("Failed to fetch route.");
//     }
//   }
//
//   Widget buildDrawer({required String userName, required dynamic userImage}) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: Colors.blue),
//             child: Text(
//               "Welcome, $userName",
//               style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
//             ),
//           ),
//           ListTile(
//             title: const Text("Home"),
//             onTap: () {},
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// //
// // class Homepage extends StatefulWidget {
// //   const Homepage({super.key});
// //
// //   @override
// //   State<Homepage> createState() => _HomepageState();
// // }
// //
// // class _HomepageState extends State<Homepage> {
// //
// //   final user=FirebaseAuth.instance.currentUser;
// //
// //   signOut()async{
// //     await FirebaseAuth.instance.signOut();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text("Homepage"),),
// //       body: Center(
// //         child: Text('${user!.email}'),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //             onPressed: (()=>signOut()),
// //           child: Icon(Icons.login_rounded),
// //       ),
// //     );
// //   }
// // }
