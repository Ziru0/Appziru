import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lage/components/homepage.dart';
import 'package:lage/components/signup/login_page.dart';
import 'package:lage/components/signup/profilesetup.dart';
import 'package:lage/components/views/homescreen.dart';
import 'package:lage/components/wrapper.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lage/components/tabpages/profilepages/my_profile.dart';
import 'package:lage/components/utils/app_colors.dart';
import 'package:lage/components/views/payment.dart';
import 'package:latlong2/latlong.dart';
import '../../dbHelper/monggodb.dart';
import '../utils/app_colors.dart';

import 'dbHelper/monggodb.dart';


void main()async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MongoDatabase.connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return  GetMaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(textTheme),
      ),
      home:    Wrapper (),
    );
  }
}




