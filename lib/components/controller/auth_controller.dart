// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:get/get.dart';
// import 'package:get/get_state_manager/src/simple/get_controllers.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
//
// import 'controllerconstants.dart';
//
//
// Future<List<dynamic>?> showORSAutocomplete(BuildContext context, String query) async {
//   const String apiKey = AppConstants0.kOpenRouteServiceApiKey;
//
//   // Ensure the query is not empty
//   if (query.isEmpty) return null;
//
//   final Uri uri = Uri.parse(
//       'https://api.openrouteservice.org/geocode/autocomplete?api_key=$apiKey&text=$query&boundary.country=PK&size=5');
//
//   try {
//     final response = await http.get(uri);
//
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//
//       // Return the list of suggestions
//       return data['features'];
//     } else {
//       debugPrint('Failed to fetch suggestions: ${response.body}');
//       return null;
//     }
//   } catch (e) {
//     debugPrint('Error fetching autocomplete: $e');
//     return null;
//   }
// }
//
// class MapController extends GetxController {
//
//   var polyline = <Polyline>{}.obs;
//
//   void drawPolyline(LatLng source, LatLng destination) async {
//     polyline.clear();
//     // Fetch route data and add to polyline
//   }
// }


// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart' as geoCoding;
// import 'package:google_fonts/google_fonts.dart';
// import 'package:get/get.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:lage/components/tabpages/profilepages/my_profile.dart';
// import 'package:lage/components/utils/app_colors.dart';
// import 'package:lage/components/views/payment.dart';
// import 'package:latlong2/latlong.dart' as LatLong;
// import '../../dbHelper/monggodb.dart';
// import '../utils/app_colors.dart';
// import 'controller/auth_controller.dart';
// import 'controller/controllerconstants.dart';
// import 'controller/polylines_handler.dart';
//
// class homescreen extends StatefulWidget {
//   const homescreen({super.key});
//
//   @override
//   State<homescreen> createState() => _homescreenState();
// }
//
// class _homescreenState extends State<homescreen> {
//   GoogleMapController? myMapController; // Controller for Google Map
//
//   late LatLng destination;
//   Set<Marker> markers = {};
//   List<dynamic>? suggestions = [];
//
//   void searchLocations(String query) async {
//     final results = await showORSAutocomplete(context, query);
//     setState(() {
//       suggestions = results ?? [];
//     });
//   }
//
//   Map<String, dynamic>? profileData;
//   bool isLoading = true;
//   late Uint8List markIcons;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchProfileData();
//     _loadMarkerIcon();
//   }
//
//   Future<void> _loadMarkerIcon() async {
//     // Load the icon as a byte array from the assets
//     final ByteData data = await rootBundle.load('assets/marker_icon.png');
//     markIcons = data.buffer.asUint8List(); // Convert to byte list
//   }
//
//   // Fetch profile data from MongoDB
//   Future<void> _fetchProfileData() async {
//     try {
//       var user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         String firebaseId = user.uid;
//         var data = await MongoDatabase.getOne(firebaseId); // Fetch data based on firebaseId
//         setState(() {
//           profileData = data;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching user profile: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   final user=FirebaseAuth.instance.currentUser;
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }
//
//     if (profileData == null) {
//       return const Center(
//         child: Text("No user data found."),
//       );
//     }
//
//     String name = profileData!['fullname'] ?? 'User Name';
//     String? profileImage = profileData!['profilePicture'];
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background or other widgets can go here
//
//           // Profile Section positioned at the top
//           Positioned(
//             top: 60, // Position it at the top
//             left: 20,
//             right: 20,
//             child: Container(
//               width: MediaQuery.of(context).size.width,
//               height: MediaQuery.of(context).size.width * 0.5,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       image: profileImage == null
//                           ? const DecorationImage(
//                         image: AssetImage('assets/person.png'),
//                         fit: BoxFit.fill,
//                       )
//                           : DecorationImage(
//                         image: NetworkImage(profileImage),
//                         fit: BoxFit.fill,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 15),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       RichText(
//                         text: TextSpan(
//                           children: [
//                             const TextSpan(
//                               text: 'Good Morning, ',
//                               style: TextStyle(color: Colors.black, fontSize: 14),
//                             ),
//                             TextSpan(
//                               text: name,
//                               style: const TextStyle(
//                                 color: Colors.green,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const Text(
//                         "Where are you going?",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Add other widgets below using Stack and Positioned
//           Positioned(
//             top: MediaQuery.of(context).size.width * 0.5 + 50, // Below the profile section
//             left: 20,
//             right: 20,
//             child: Column(
//               children: [
//                 buildTextField(),
//                 const SizedBox(height: 20),
//                 buildTextFieldForSource(),
//               ],
//             ),
//           ),
//
//           // Bottom Sheet positioned at the bottom using Stack
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: buildBottomSheet(),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
//   TextEditingController destinationController = TextEditingController();
//   TextEditingController sourceController = TextEditingController();
//
//   bool showSourceField = false;
//
//
//
//   Widget buildTextField() {
//     return Positioned(
//       top: 170,
//       left: 20,
//       right: 20,
//       child: Container(
//         width: Get.width,
//         height: 50,
//         padding: EdgeInsets.only(left: 15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 spreadRadius: 4,
//                 blurRadius: 10)
//           ],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: TextFormField(
//           controller: destinationController,
//           readOnly: true,
//           onTap: () async {
//             // OpenRouteService API URL and parameters
//             final String baseUrl = 'https://api.openrouteservice.org/geocode/autocomplete';
//             final String apiKey = '5b3ce3597851110001cf624806cb530231bd49338fd6a9a3cd129e38';  // Replace with your ORS API Key
//
//             // Request to ORS API for place suggestions
//             final response = await http.get(Uri.parse('$baseUrl?api_key=$apiKey&text=${destinationController.text}'));
//
//             if (response.statusCode == 200) {
//               var data = json.decode(response.body);
//               var suggestions = data['features'];
//
//               // Assuming the first suggestion is what the user selects
//               if (suggestions.isNotEmpty) {
//                 String selectedPlace = suggestions[0]['properties']['label'];
//                 destinationController.text = selectedPlace;
//
//                 // Fetching location details for selected place
//                 List<geoCoding.Location> locations = await geoCoding.locationFromAddress(selectedPlace);
//
//                 destination = LatLng(locations.first.latitude, locations.first.longitude);
//
//                 markers.add(Marker(
//                   markerId: MarkerId(selectedPlace),
//                   infoWindow: InfoWindow(
//                     title: 'Destination: $selectedPlace',
//                   ),
//                   position: destination,
//                   icon: BitmapDescriptor.fromBytes(markIcons),
//                 ));
//
//                 myMapController!.animateCamera(CameraUpdate.newCameraPosition(
//                     CameraPosition(target: destination, zoom: 14)
//                 ));
//
//                 setState(() {
//                   showSourceField = true;
//                 });
//               }
//             } else {
//               print('Error fetching suggestions from ORS');
//             }
//           },
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//           decoration: InputDecoration(
//             hintText: 'Search for a destination',
//             hintStyle: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//             suffixIcon: Padding(
//               padding: const EdgeInsets.only(left: 10),
//               child: Icon(
//                 Icons.search,
//               ),
//             ),
//             border: InputBorder.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//
//
//   Widget buildTextFieldForSource() {
//     return Positioned(
//       top: 230,
//       left: 20,
//       right: 20,
//       child: Container(
//         width: Get.width,
//         height: 50,
//         padding: EdgeInsets.only(left: 15),
//         decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   spreadRadius: 4,
//                   blurRadius: 10)
//             ],
//             borderRadius: BorderRadius.circular(8)),
//         child: TextFormField(
//           controller: sourceController,
//           readOnly: true,
//           onTap: () async {
//             buildSourceSheet(sourceController: sourceController);
//           },
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//           decoration: InputDecoration(
//             hintText: 'From:',
//             hintStyle: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//             suffixIcon: Padding(
//               padding: const EdgeInsets.only(left: 10),
//               child: Icon(
//                 Icons.search,
//               ),
//             ),
//             border: InputBorder.none,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildCurrentLocationIcon() {
//     return Align(
//       alignment: Alignment.bottomRight,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 30, right: 8),
//         child: CircleAvatar(
//           radius: 20,
//           backgroundColor: Colors.green,
//           child: Icon(
//             Icons.my_location,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildNotificationIcon() {
//     return Align(
//       alignment: Alignment.bottomLeft,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 30, left: 8),
//         child: CircleAvatar(
//           radius: 20,
//           backgroundColor: Colors.white,
//           child: Icon(
//             Icons.notifications,
//             color: Color(0xffC3CDD6),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildBottomSheet() {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         width: Get.width * 0.8,
//         height: 25,
//         decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   spreadRadius: 4,
//                   blurRadius: 10)
//             ],
//             borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(12), topLeft: Radius.circular(12))),
//         child: Center(
//           child: Container(
//             width: Get.width * 0.6,
//             height: 4,
//             color: Colors.black45,
//           ),
//         ),
//       ),
//     );
//   }
//
//   buildDrawerItem(
//       {required String title,
//         required Function onPressed,
//         Color color = Colors.black,
//         double fontSize = 20,
//         FontWeight fontWeight = FontWeight.w700,
//         double height = 45,
//         bool isVisible = false}) {
//     return SizedBox(
//       height: height,
//       child: ListTile(
//         contentPadding: EdgeInsets.all(0),
//         // minVerticalPadding: 0,
//         dense: true,
//         onTap: () => onPressed(),
//         title: Row(
//           children: [
//             Text(
//               title,
//               style: GoogleFonts.poppins(
//                   fontSize: fontSize, fontWeight: fontWeight, color: color),
//             ),
//             const SizedBox(
//               width: 5,
//             ),
//             isVisible
//                 ? CircleAvatar(
//               backgroundColor: AppColors.greenColor,
//               radius: 15,
//               child: Text(
//                 '1',
//                 style: GoogleFonts.poppins(color: Colors.white),
//               ),
//             )
//                 : Container()
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget buildDrawer(BuildContext context) {
//     return isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : Drawer(
//       child: Column(
//         children: [
//           InkWell(
//             onTap: () {
//               Get.to(() => const ProfilePage());
//             },
//             child: SizedBox(
//               height: 150,
//               child: DrawerHeader(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         image: (profileData?['profilePicture'] == null)
//                             ? const DecorationImage(
//                           image: AssetImage('assets/person.png'),
//                           fit: BoxFit.fill,
//                         )
//                             : DecorationImage(
//                           image: NetworkImage(
//                               profileData!['profilePicture']),
//                           fit: BoxFit.fill,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Good Morning, ',
//                             style: GoogleFonts.poppins(
//                               color: Colors.black.withOpacity(0.28),
//                               fontSize: 14,
//                             ),
//                           ),
//                           Text(
//                             profileData?['fullname'] ?? 'Mark',
//                             style: GoogleFonts.poppins(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                             maxLines: 1,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 30),
//             child: Column(
//               children: [
//                 buildDrawerItem(
//                     title: 'Payment History',
//                     onPressed: () => Get.to(() => PaymentScreen())),
//                 buildDrawerItem(
//                     title: 'Ride History',
//                     onPressed: () {},
//                     isVisible: true),
//                 buildDrawerItem(title: 'Invite Friends', onPressed: () {}),
//                 buildDrawerItem(title: 'Promo Codes', onPressed: () {}),
//                 buildDrawerItem(title: 'Settings', onPressed: () {}),
//                 buildDrawerItem(title: 'Support', onPressed: () {}),
//                 buildDrawerItem(
//                   title: 'Log Out',
//                   onPressed: () {
//                     FirebaseAuth.instance.signOut();
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const Spacer(),
//           const Divider(),
//           Container(
//             padding:
//             const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//             child: Column(
//               children: [
//                 buildDrawerItem(
//                     title: 'Do more',
//                     onPressed: () {},
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black.withOpacity(0.15),
//                     height: 20),
//                 const SizedBox(height: 20),
//                 buildDrawerItem(
//                     title: 'Get food delivery',
//                     onPressed: () {},
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black.withOpacity(0.15),
//                     height: 20),
//                 buildDrawerItem(
//                     title: 'Make money driving',
//                     onPressed: () {},
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black.withOpacity(0.15),
//                     height: 20),
//                 buildDrawerItem(
//                   title: 'Rate us on store',
//                   onPressed: () {},
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.black.withOpacity(0.15),
//                   height: 20,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
//
//   void buildSourceSheet({
//     required TextEditingController sourceController,
//   }) {
//
//     Get.bottomSheet(
//       Container(
//         width: Get.width,
//         height: Get.height * 0.5,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         decoration: const BoxDecoration(
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(8),
//             topRight: Radius.circular(8),
//           ),
//           color: Colors.white,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),
//             const Text(
//               "Select Your Location",
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Home Address",
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             InkWell(
//               onTap: () {
//                 Get.back(); // Close the bottom sheet
//                 sourceController.text = "Home Address"; // Set the selected value
//               },
//               child: _buildAddressContainer("Home Address"),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Current Address",
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             InkWell(
//               onTap: () {
//                 Get.back();
//                 sourceController.text = "Current Address";
//               },
//               child: _buildAddressContainer("Business Address"),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Search for Address",
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Center(
//               child: Column(
//                 children: [
//                   TextButton(
//                     onPressed: () {
//
//                       // Define the action to perform when the button is clicked
//                       print("Search button pressed");
//                     },
//                     child: const Text(
//                       "Search for Address",
//                       style: TextStyle(
//
//                         color: Colors.black,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildAddressContainer(String label) {
//     return Container(
//       width: Get.width,
//       height: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             spreadRadius: 4,
//             blurRadius: 10,
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.black,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//             textAlign: TextAlign.start,
//           ),
//         ],
//       ),
//     );
//   }
//
// }
