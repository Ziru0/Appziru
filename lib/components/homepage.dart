  import 'dart:convert';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:get/get.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:lage/components/views/invites.dart';
  import 'package:lage/components/views/payment.dart';
  import 'package:lage/components/views/promo_codes.dart';
  import 'package:lage/components/views/ride_history.dart';
  import 'package:lage/components/views/settings.dart';
  import 'package:lage/components/views/support.dart';
  import 'package:latlong2/latlong.dart';
  import 'package:http/http.dart' as http;
  import '../dbHelper/monggodb.dart';

  class HomeScreen1 extends StatefulWidget {
    const HomeScreen1({super.key});

    @override
    State<HomeScreen1> createState() => _HomeScreen1State();
  }

  class _HomeScreen1State extends State<HomeScreen1> {
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
        print('Error fetching profile data: $e');
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

    Future<void> fetchRoute() async {
      if (startCoordinates == null || endCoordinates == null) return;

      final apiKey = '5b3ce3597851110001cf624811cef0354a884bb2be1bed7e3fa689b0';
      final url =
          'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${startCoordinates!.longitude},${startCoordinates!.latitude}&end=${endCoordinates!.longitude},${endCoordinates!.latitude}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'];
        setState(() {
          polylineCoordinates = coordinates
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();
        });
      } else {
        throw Exception('Failed to fetch route');
      }
    }

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
              ],
            ),
            buildProfileTile(
              name: profileData?['fullname'] ?? 'N/A', // Use the dynamic full name
              imageUrl: profileData?['profilePicture'], // Use the dynamic profile picture URL
            ),
            buildTextField(),
            buildTextFieldForSource(), // Ensure this is displayed correctly
            buildCurrentLocationIcon(),
            buildBottomSheet(),
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
        top: 280,
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

    Widget buildTextFieldForSource() {
      return Positioned(
        top: 340,
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
                            print("Showing Ride Confirmation Sheet");

                            // Ensure display
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              buildRideConfirmationSheet();
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
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    spreadRadius: 4,
                    blurRadius: 10)
              ],
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12), topLeft: Radius.circular(12))),
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
                    image: NetworkImage(profileData?['profilePicture']), // Dynamic profile picture
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

    buildRideConfirmationSheet() {
      Get.bottomSheet(Container(
        width: Get.width,
        height: Get.height * 0.4,
        padding: EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(12), topLeft: Radius.circular(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            Center(
              child: Container(
                width: Get.width * 0.2,
                height: 8,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), color: Colors.grey),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            textWidget(
                text: 'Select an option:',
                fontSize: 18,
                fontWeight: FontWeight.bold),
            const SizedBox(
              height: 20,
            ),
            buildDriversList(),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MaterialButton(
                    onPressed: () {},
                    child: textWidget(
                      text: 'Confirm',
                      color: Colors.white,
                    ),
                    color: Colors.white,
                    shape: StadiumBorder(),
                  )
                ],
              ),
            )
          ],
        ),
      ));
    }

    int selectedRide = 0;

    buildDriversList() {
      return Container(
        height: 90,
        width: Get.width,
        child: StatefulBuilder(builder: (context, set) {
          return ListView.builder(
            itemBuilder: (ctx, i) {
              return InkWell(
                onTap: () {
                  set(() {
                    selectedRide = i;
                  });
                },
                child: buildDriverCard(selectedRide == i),
              );
            },
            itemCount: 3,
            scrollDirection: Axis.horizontal,
          );
        }),
      );
    }

    buildDriverCard(bool selected) {
      return Container(
        margin: EdgeInsets.only(right: 8, left: 8, top: 4, bottom: 4),
        height: 85,
        width: 165,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: selected
                      ? Color(0xff2DBB54).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  offset: Offset(0, 5),
                  blurRadius: 5,
                  spreadRadius: 1)
            ],
            borderRadius: BorderRadius.circular(12),
            color: selected ? Color(0xff2DBB54) : Colors.grey),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget(
                      text: 'Standard',
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                  textWidget(
                      text: '\$9.90',
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                  textWidget(
                      text: '3 MIN',
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.normal,
                      fontSize: 12),
                ],
              ),
            ),
            Positioned(
                right: -20,
                top: 0,
                bottom: 0,
                child: Image.asset('assets/Mask Group 2.png'))
          ],
        ),
      );
    }

    Widget textWidget({required String text,double fontSize = 12, FontWeight fontWeight = FontWeight.normal,Color color = Colors.black}){
      return Text(text, style: GoogleFonts.poppins(fontSize: fontSize,fontWeight: fontWeight,color: color),);
    }
  }
